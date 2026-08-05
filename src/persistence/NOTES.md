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
- If a configured path already exists in the image, it is moved aside to
  `<path>.backup` and its contents are seeded into the volume on first creation.
  Later rebuilds keep the volume's contents and leave the seed untouched.
- Configured paths must not collide after flattening (`/home/a_b` and
  `/home/a/b` both map to `home_a_b`); the feature install fails if they do.
