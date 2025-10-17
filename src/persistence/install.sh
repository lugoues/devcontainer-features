#!/usr/bin/env bash

set -euo pipefail

PERSIST_DIR="/mnt/persistence-data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"

cat > "$PERSIST_POST_CREATE" << EOF
#!/bin/sh
set -e

SUDO_CMD=""
[ "\${USER}" != "root" ] && SUDO_CMD="sudo"

EOF

chmod +x "${PERSIST_POST_CREATE}"

expand_path() {
    local path="$1"
    path="${path/#\~/${_REMOTE_USER_HOME}}"
    path="${path/#\$HOME/${_REMOTE_USER_HOME}}"
    echo "$(realpath -m "${path}")"
}

append_post_create() {
    echo "$1" >> "${PERSIST_POST_CREATE}"
}

create_symlink() {
    local original_path="$1"
    local persist_path="$2"
    local parent_dir="$(dirname "${original_path}")"

    mkdir -p "${parent_dir}"

    if [[ -e "${original_path}" ]]; then
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"

    append_post_create "\${SUDO_CMD} chown -R \$USER \"${parent_dir}\""
}

# Process directories
if [[ -n "${DIRECTORIES:-}" ]]; then
    IFS=':' read -ra DIR_ARRAY <<< "${DIRECTORIES}"
    for path in "${DIR_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        safe_name="${original_path//\//_}"
        persist_path="${PERSIST_DIR}/${safe_name#_}"

        append_post_create "echo \"Setting up persistent directory: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_path}\""
        append_post_create "\${SUDO_CMD} chown -R \$USER \"${persist_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

# Process files
if [[ -n "${FILES:-}" ]]; then
    IFS=':' read -ra FILE_ARRAY <<< "${FILES}"
    for path in "${FILE_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        safe_name="${original_path//\//_}"
        persist_path="${PERSIST_DIR}/${safe_name#_}"

        persist_parent="$(dirname "${persist_path}")"

        append_post_create "echo \"Setting up persistent file: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_parent}\""
        append_post_create "\${SUDO_CMD} touch \"${persist_path}\""
        append_post_create "\${SUDO_CMD} chown \$USER \"${persist_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

append_post_create "echo \"Setting owner for ${PERSIST_DIR} to \${USER}\""
append_post_create "\${SUDO_CMD} chown -R \$USER "${PERSIST_DIR}""
