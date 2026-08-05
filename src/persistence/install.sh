#!/usr/bin/env bash

set -euo pipefail

PERSIST_DIR="/mnt/persistence-data"
PERSIST_POST_CREATE="/usr/local/share/persistence_post_create"
PERSIST_POST_START="/usr/local/share/persistence_post_start"
INIT_MARKER_DIR="${PERSIST_DIR}/.persistence-init"

REMOTE_USER="${_REMOTE_USER:-root}"

# GNU coreutils realpath is required; busybox/POSIX realpath lacks -s/-m.
if ! realpath -sm / > /dev/null 2>&1; then
    echo "ERROR: the persistence feature requires GNU coreutils realpath (supporting -s and -m)" >&2
    exit 1
fi

# Guards against two configured paths flattening to the same volume name.
declare -A SEEN_NAMES

write_script_header() {
    cat > "$1" << EOF
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

# Tracks which paths completed first-time setup, so data the user
# intentionally emptied is not re-seeded from the image layer on rebuilds.
\${SUDO_CMD} mkdir -p "${INIT_MARKER_DIR}"

EOF
    chmod +x "$1"
}

write_script_header "${PERSIST_POST_CREATE}"
write_script_header "${PERSIST_POST_START}"

expand_path() {
    local path="$1"
    path="${path/#\~/${_REMOTE_USER_HOME}}"
    path="${path/#\$\{HOME\}/${_REMOTE_USER_HOME}}"
    path="${path/#\$HOME/${_REMOTE_USER_HOME}}"
    # -s: normalize lexically without resolving symlinks, so a re-run over an
    # already-symlinked path keeps the original location, not the volume path.
    realpath -sm "${path}"
}

# Sets PERSIST_PATH and MARKER_PATH; fails the install if the flattened name
# collides with a previously configured path (e.g. /home/a_b and /home/a/b
# both map to home_a_b).
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
    MARKER_PATH="${INIT_MARKER_DIR}/${name}"
}

append_post_create() {
    echo "$1" >> "${PERSIST_POST_CREATE}"
}

append_post_start() {
    echo "$1" >> "${PERSIST_POST_START}"
}

# Creates any missing parents of $1 and fixes ownership on the topmost
# directory this created, never on pre-existing parents like $HOME.
# Install runs as root at build time, so ownership is fixed here rather
# than in the lifecycle scripts.
create_owned_parents() {
    local parent_dir="$1"

    local top_created=""
    local probe="${parent_dir}"
    while [[ ! -d "${probe}" && "${probe}" != "/" ]]; do
        top_created="${probe}"
        probe="$(dirname "${probe}")"
    done

    mkdir -p "${parent_dir}"

    if [[ -n "${top_created}" ]]; then
        chown -R "${REMOTE_USER}" "${top_created}"
    fi
}

create_symlink() {
    local original_path="$1"
    local persist_path="$2"

    create_owned_parents "$(dirname "${original_path}")"

    if [[ -L "${original_path}" && "$(readlink "${original_path}")" == "${persist_path}" ]]; then
        # Re-run over an earlier install: replace our own (likely dangling) symlink.
        rm -f "${original_path}"
    elif [[ -e "${original_path}" || -L "${original_path}" ]]; then
        # Regular file/dir, or a foreign symlink (dotfile manager, base image):
        # preserve it as the backup.
        # Clear any stale backup first; mv into an existing directory would
        # nest instead of replace.
        rm -rf "${original_path}.backup"
        mv "${original_path}" "${original_path}.backup"
    fi

    ln -s "${persist_path}" "${original_path}"
    chown -h "${REMOTE_USER}" "${original_path}"
}

# Bind-mount targets must exist; content already in the image is left in
# place so the post-start script can seed the volume from it.
create_mount_target() {
    local original_path="$1"
    local kind="$2"

    if [[ -L "${original_path}" ]]; then
        # mount --bind follows symlinks, which would leave a deletable symlink
        # at the configured path — the exact thing bind mode exists to prevent.
        # Replace it with a real dir/file, dereferencing its content so the
        # post-start script can still seed the volume from it.
        local link_target
        link_target="$(readlink -f "${original_path}" || true)"
        rm -f "${original_path}"
        if [[ "${kind}" == "dir" ]]; then
            mkdir "${original_path}"
            if [[ -n "${link_target}" && -d "${link_target}" ]]; then
                cp -a "${link_target}/." "${original_path}/"
            fi
        else
            touch "${original_path}"
            if [[ -n "${link_target}" && -f "${link_target}" ]]; then
                cp -aL "${link_target}" "${original_path}"
            fi
        fi
        chown -R "${REMOTE_USER}" "${original_path}"
    elif [[ ! -e "${original_path}" ]]; then
        create_owned_parents "$(dirname "${original_path}")"
        if [[ "${kind}" == "dir" ]]; then
            mkdir "${original_path}"
        else
            touch "${original_path}"
        fi
        chown "${REMOTE_USER}" "${original_path}"
    fi
}

# Process symlinked directories
if [[ -n "${DIRECTORIES:-}" ]]; then
    IFS=':' read -ra DIR_ARRAY <<< "${DIRECTORIES}"
    for path in "${DIR_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"
        marker_path="${MARKER_PATH}"

        append_post_create "echo \"Setting up persistent directory: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_path}\""
        append_post_create "if [ ! -e \"${marker_path}\" ] && [ -d \"${original_path}.backup\" ] && [ -z \"\$(ls -A \"${persist_path}\")\" ]; then"
        append_post_create "    echo \"Seeding ${persist_path} from ${original_path}.backup\""
        append_post_create "    \${SUDO_CMD} cp -a \"${original_path}.backup/.\" \"${persist_path}/\""
        append_post_create "fi"
        append_post_create "\${SUDO_CMD} chown -R \"\${TARGET_USER}\" \"${persist_path}\""
        append_post_create "\${SUDO_CMD} touch \"${marker_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

# Process symlinked files
if [[ -n "${FILES:-}" ]]; then
    IFS=':' read -ra FILE_ARRAY <<< "${FILES}"
    for path in "${FILE_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"
        marker_path="${MARKER_PATH}"

        persist_parent="$(dirname "${persist_path}")"

        append_post_create "echo \"Setting up persistent file: ${path}\""
        append_post_create "\${SUDO_CMD} mkdir -p \"${persist_parent}\""
        append_post_create "if [ ! -e \"${marker_path}\" ] && [ -f \"${original_path}.backup\" ] && [ ! -e \"${persist_path}\" ]; then"
        append_post_create "    echo \"Seeding ${persist_path} from ${original_path}.backup\""
        append_post_create "    \${SUDO_CMD} cp -aL \"${original_path}.backup\" \"${persist_path}\""
        append_post_create "fi"
        append_post_create "\${SUDO_CMD} touch \"${persist_path}\""
        append_post_create "\${SUDO_CMD} chown \"\${TARGET_USER}\" \"${persist_path}\""
        append_post_create "\${SUDO_CMD} touch \"${marker_path}\""

        create_symlink "${original_path}" "${persist_path}"
    done
fi

# Process bind-mounted directories. Mounts do not survive container restarts,
# so these run from the post-start script on every start. Seeding happens
# before the mount goes over the original path, or the image content would be
# shadowed while the volume is still empty.
if [[ -n "${BINDDIRECTORIES:-}" ]]; then
    IFS=':' read -ra BIND_DIR_ARRAY <<< "${BINDDIRECTORIES}"
    for path in "${BIND_DIR_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"
        marker_path="${MARKER_PATH}"

        append_post_start "echo \"Setting up bind-mounted directory: ${path}\""
        append_post_start "if ! mountpoint -q \"${original_path}\" 2> /dev/null; then"
        append_post_start "    \${SUDO_CMD} mkdir -p \"${persist_path}\" \"${original_path}\""
        append_post_start "    if [ ! -e \"${marker_path}\" ]; then"
        append_post_start "        if [ -z \"\$(ls -A \"${persist_path}\")\" ]; then"
        append_post_start "            echo \"Seeding ${persist_path} from ${original_path}\""
        append_post_start "            \${SUDO_CMD} cp -a \"${original_path}/.\" \"${persist_path}/\""
        append_post_start "        fi"
        append_post_start "        \${SUDO_CMD} chown -R \"\${TARGET_USER}\" \"${persist_path}\""
        append_post_start "        \${SUDO_CMD} touch \"${marker_path}\""
        append_post_start "    fi"
        append_post_start "    \${SUDO_CMD} mount --bind \"${persist_path}\" \"${original_path}\""
        append_post_start "fi"

        create_mount_target "${original_path}" "dir"
    done
fi

# Process bind-mounted files
if [[ -n "${BINDFILES:-}" ]]; then
    IFS=':' read -ra BIND_FILE_ARRAY <<< "${BINDFILES}"
    for path in "${BIND_FILE_ARRAY[@]}"; do
        [[ -z "${path}" ]] && continue

        original_path=$(expand_path "${path}")
        resolve_persist_path "${original_path}"
        persist_path="${PERSIST_PATH}"
        marker_path="${MARKER_PATH}"

        persist_parent="$(dirname "${persist_path}")"

        append_post_start "echo \"Setting up bind-mounted file: ${path}\""
        append_post_start "if ! mountpoint -q \"${original_path}\" 2> /dev/null; then"
        append_post_start "    \${SUDO_CMD} mkdir -p \"${persist_parent}\""
        append_post_start "    if [ ! -e \"${marker_path}\" ] && [ -f \"${original_path}\" ] && [ ! -e \"${persist_path}\" ]; then"
        append_post_start "        echo \"Seeding ${persist_path} from ${original_path}\""
        append_post_start "        \${SUDO_CMD} cp -aL \"${original_path}\" \"${persist_path}\""
        append_post_start "    fi"
        append_post_start "    \${SUDO_CMD} touch \"${persist_path}\" \"${original_path}\""
        append_post_start "    \${SUDO_CMD} chown \"\${TARGET_USER}\" \"${persist_path}\""
        append_post_start "    \${SUDO_CMD} touch \"${marker_path}\""
        append_post_start "    \${SUDO_CMD} mount --bind \"${persist_path}\" \"${original_path}\""
        append_post_start "fi"

        create_mount_target "${original_path}" "file"
    done
fi

append_post_create "echo \"Setting owner for ${PERSIST_DIR} to \${TARGET_USER}\""
append_post_create "\${SUDO_CMD} mkdir -p \"${PERSIST_DIR}\""
append_post_create "\${SUDO_CMD} chown -R \"\${TARGET_USER}\" \"${PERSIST_DIR}\""
