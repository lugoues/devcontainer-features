#!/usr/bin/env bash

set -euo pipefail

PERSIST_DIR="/mnt/persistence_data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"

tee "$PERSIST_POST_CREATE" > /dev/null \
<< EOF
#!/bin/sh
set -e
EOF

chmod +x "${PERSIST_POST_CREATE}"

IFS=':' read -ra PATH_ARRAY <<< "${PATHS}"
for path in "${PATH_ARRAY[@]}"; do
    [[ -z "${path}" ]] && continue

    # Replace ~ or $HOME with $_REMOTE_USER_HOME
    path="${path/#\~/${_REMOTE_USER_HOME}}"
    path="${path/#\$HOME/${_REMOTE_USER_HOME}}"

    # Build safe persist_path
    original_path=$(realpath -m "${path}")
    safe_name="${original_path//\//_}"
    persist_path="${PERSIST_DIR}/${safe_name#_}"

    # Create target/soource directories
    mkdir -p "${persist_path}"
    mkdir -p "$(dirname "${original_path}")"


    # Backup and remove existing directory if it exists
    if [[ -d "${original_path}" ]]; then
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"
done

tee -a "$PERSIST_POST_CREATE" > /dev/null \
<< EOF

echo "Setting owner for ${PERSIST_DIR} to \${USER}"
sudo chown -R \$USER "${PERSIST_DIR}"

EOF
