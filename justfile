test feature:
  devcontainer features test \
    --features {{feature}} \
    --base-image mcr.microsoft.com/devcontainers/base:debian .

test-all:
  devcontainer features test \
    --base-image mcr.microsoft.com/devcontainers/base:debian .
