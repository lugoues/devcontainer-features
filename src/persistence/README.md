
# Persistence (persistence)

Store data you wish to persist between container rebuilds.

## Example Usage

```json
"features": {
    "ghcr.io/lugoues/devcontainer-features/persistence:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| directories | Colon separated list of directory paths to persist via symlink. | string | - |
| files | Colon separated list of file paths to persist via symlink. | string | - |
| bindDirectories | Colon separated list of directory paths to persist via bind mount, for tools that replace symlinks (e.g. ~/.claude). Requires CAP_SYS_ADMIN. | string | - |
| bindFiles | Colon separated list of file paths to persist via bind mount, for tools that replace symlinks (e.g. ~/.claude.json). Requires CAP_SYS_ADMIN. | string | - |

## Requirements

- The persistence volume is mounted at runtime owned by root. When the remote
  user is not root, the setup script needs **passwordless sudo** (as provided by
  `common-utils`); otherwise container creation fails with a clear error.
- Paths may use `~`, `$HOME`, or `${HOME}` prefixes; they resolve to the remote
  user's home.
- The build image needs GNU coreutils `realpath` (any debian/ubuntu-family
  image qualifies; busybox-based images such as Alpine do not). The install
  fails with a clear error otherwise.

## Behavior

- Each configured path is replaced with a symlink into a per-devcontainer volume
  (`persistence-${devcontainerId}`), so contents survive rebuilds.
- Paths listed in `bindDirectories`/`bindFiles` are bind-mounted from the volume
  instead of symlinked, on every container start (`postStartCommand`). Use this
  for tools that delete and recreate their config path, which would destroy a
  symlink (the Claude Code extension does this with `~/.claude`). A mountpoint
  cannot be unlinked, so it survives. Bind mounts need `CAP_SYS_ADMIN` (e.g. a
  privileged container, such as one running docker-in-docker); the post-start
  script fails loudly if the mount cannot be made.
- If a configured path already exists in the image, it is moved aside to
  `<path>.backup` and its contents are seeded into the volume on first creation.
  This includes paths that are symlinks (e.g. from a dotfile manager); their
  content is captured and the original link preserved as the backup.
- Seeding happens exactly once per path, tracked via markers in
  `.persistence-init/` inside the volume. Later rebuilds keep the volume's
  contents as-is, including files or directories you intentionally emptied.
- Configured paths must not collide after flattening (`/home/a_b` and
  `/home/a/b` both map to `home_a_b`); the feature install fails if they do.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lugoues/devcontainer-features/blob/main/src/persistence/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
