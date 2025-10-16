#!/usr/bin/env bash

set -euo pipefail

sudo_if() {
    COMMAND="$*"

    if [ "$(id -u)" -ne 0 ]; then
        sudo $COMMAND
    else
        $COMMAND
    fi
}

PERSIST_DIR="/mnt/persistence_data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"

tee "$PERSIST_POST_CREATE" > /dev/null \
<< EOF
#!/bin/sh
set -e

SUDO_CMD=""
[ "\${USER}" != "root" ] && SUDO_CMD="sudo"

echo "Setting owner for ${PERSIST_DIR} to \${USER}"
\${SUDO_CMD} chown -R \$USER "${PERSIST_DIR}"

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

    # Create target directory
    sudo_if sudo mkdir -p "${persist_path}"

    # Create parent directory if needed
    parent_dir="$(dirname "${original_path}")"
    mkdir -p "${parent_dir}"


    # Backup and remove existing directory if it exists
    if [[ -d "${original_path}" ]]; then
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"
w
    echo "\${SUDO_CMD} chown -R \$USER \"${parent_dir}\"" >> "${PERSIST_POST_CREATE}"
done

