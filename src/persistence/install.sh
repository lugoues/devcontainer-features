#!/usr/bin/env bash

set -euo pipefail

PERSIST_DIR="/mnt/persistence-data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"

REMOTE_USER="${_REMOTE_USER:-root}"

# GNU coreutils realpath is required; busybox/POSIX realpath lacks -s/-m.
if ! realpath -sm / > /dev/null 2>&1; then
    echo "ERROR: the persistence feature requires GNU coreutils realpath (supporting -s and -m)" >&2
    exit 1
fi

# Guards against two configured paths flattening to the same volume name.
declare -A SEEN_NAMES

cat > "$PERSIST_POST_CREATE" << EOF
#!/bin/sh
set -e

# Baked in at feature install time; \$USER is unreliable in lifecycle hooks.
TARGET_USER="${REMOTE_USER}"

# The volume is mounted at runtime owned by root, so a non-root user needs
# passwordless sudo to set it up. sudo -n fails fast instead of hanging a
# lifecycle hook on a password prompt.
SUDO_CMD=""
if [ "\$(id -un)" != "root" ]; then
    if command -v sudo > /dev/null 2>&1; then
        SUDO_CMD="sudo -n"
    else
        echo "ERROR: the persistence feature requires root or passwordless sudo to set up ${PERSIST_DIR}" >&2
        exit 1
    fi
fi

EOF

chmod +x "${PERSIST_POST_CREATE}"

expand_path() {
    local path="$1"
    path="${path/#\~/${_REMOTE_USER_HOME}}"
    path="${path/#\$\{HOME\}/${_REMOTE_USER_HOME}}"
    path="${path/#\$HOME/${_REMOTE_USER_HOME}}"
    # -s: normalize lexically without resolving symlinks, so a re-run over an
    # already-symlinked path keeps the original location, not the volume path.
    realpath -sm "${path}"
}

# Sets PERSIST_PATH; fails the install if the flattened name collides with a
# previously configured path (e.g. /home/a_b and /home/a/b both map to home_a_b).
resolve_persist_path() {
    local original_path="$1"
    local name="${original_path//\//_}"
    name="${name#_}"

    if [[ -n "${SEEN_NAMES[${name}]:-}" ]]; then
        echo "ERROR: persistence paths '${SEEN_NAMES[${name}]}' and '${original_path}' both map to '${PERSIST_DIR}/${name}'" >&2
        exit 1
    fi
    SEEN_NAMES[${name}]="${original_path}"

    PERSIST_PATH="${PERSIST_DIR}/${name}"
}

append_post_create() {
    echo "$1" >> "${PERSIST_POST_CREATE}"
}

create_symlink() {
    local original_path="$1"
    local persist_path="$2"
    local parent_dir="$(dirname "${original_path}")"

    # Record the topmost directory mkdir -p will create, so ownership is fixed
    # only on what this feature made, never on pre-existing parents like $HOME.
    local top_created=""
    local probe="${parent_dir}"
    while [[ ! -d "${probe}" && "${probe}" != "/" ]]; do
        top_created="${probe}"
        probe="$(dirname "${probe}")"
    done

    mkdir -p "${parent_dir}"

    if [[ -L "${original_path}" ]]; then
        # Re-run over an earlier install: replace the (likely dangling) symlink.
        rm -f "${original_path}"
    elif [[ -e "${original_path}" ]]; then
        # Clear any stale backup first; mv into an existing directory would
        # nest instead of replace.
        rm -rf "${original_path}.backup"
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"

    # Install runs as root at build time, so ownership is fixed here rather
    # than in the post-create script.
    if [[ -n "${top_created}" ]]; then
        chown -R "${REMOTE_USER}" "${top_created}"
    fi
    chown -h "${REMOTE_USER}" "${original_path}"
}

# Process directories
if [[ -n "${DIRECTORIES:-}" ]]; then
    IFS=':' read -ra DIR_ARRAY <<< "${DIRECTORIES}"
    for path in "${DIR_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"

        append_post_create "echo \"Setting up persistent directory: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_path}\""
        append_post_create "if [ -d \"${original_path}.backup\" ] && [ -z \"\$(ls -A \"${persist_path}\")\" ]; then"
        append_post_create "    echo \"Seeding ${persist_path} from ${original_path}.backup\""
        append_post_create "    \${SUDO_CMD} cp -a \"${original_path}.backup/.\" \"${persist_path}/\""
        append_post_create "fi"
        append_post_create "\${SUDO_CMD} chown -R \"\${TARGET_USER}\" \"${persist_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

# Process files
if [[ -n "${FILES:-}" ]]; then
    IFS=':' read -ra FILE_ARRAY <<< "${FILES}"
    for path in "${FILE_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"

        persist_parent="$(dirname "${persist_path}")"

        append_post_create "echo \"Setting up persistent file: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_parent}\""
        append_post_create "if [ -f \"${original_path}.backup\" ] && [ ! -s \"${persist_path}\" ]; then"
        append_post_create "    echo \"Seeding ${persist_path} from ${original_path}.backup\""
        append_post_create "    \${SUDO_CMD} cp -a \"${original_path}.backup\" \"${persist_path}\""
        append_post_create "fi"
        append_post_create "\${SUDO_CMD} touch \"${persist_path}\""
        append_post_create "\${SUDO_CMD} chown \"\${TARGET_USER}\" \"${persist_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

append_post_create "echo \"Setting owner for ${PERSIST_DIR} to \${TARGET_USER}\""
append_post_create "\${SUDO_CMD} mkdir -p \"${PERSIST_DIR}\""
append_post_create "\${SUDO_CMD} chown -R \"\${TARGET_USER}\" \"${PERSIST_DIR}\""
