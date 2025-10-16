#!/usr/bin/env bash

set -euo pipefail

PERSIST_DIR="/mnt/persistence-data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"

cat > "$PERSIST_POST_CREATE" << EOF
#!/usr/bin/env bash

SUDO_CMD=""
[ "\${USER}" != "root" ] && SUDO_CMD="sudo"

EOF

IFS=':' read -ra PATH_ARRAY <<< "${PATHS}"
for path in "${PATH_ARRAY[@]}"; do
    [[ -z "${path}" ]] && continue

    path="${path/#\~/${_REMOTE_USER_HOME}}"
    path="${path/#\$HOME/${_REMOTE_USER_HOME}}"

    original_path=$(realpath -m "${path}")
    safe_name="${original_path//\//_}"
    persist_path="${PERSIST_DIR}/${safe_name#_}"

    # Add directory creation to post-create
    echo "Setting up ${path}" >> "${PERSIST_POST_CREATE}"
    echo "\${SUDO_CMD} mkdir -p \"${persist_path}\"" >> "${PERSIST_POST_CREATE}"

    parent_dir="$(dirname "${original_path}")"
    mkdir -p "${parent_dir}"

    if [[ -d "${original_path}" ]]; then
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"

    echo "\${SUDO_CMD} chown -R \$USER \"${parent_dir}\"" >> "${PERSIST_POST_CREATE}"
done

cat >> "$PERSIST_POST_CREATE" << EOF

echo "Setting owner for ${PERSIST_DIR} to \${USER}"
\${SUDO_CMD} chown -R \$USER "${PERSIST_DIR}"

EOF

chmod +x "${PERSIST_POST_CREATE}"
