#!/usr/bin/env bash
set -e
set -x

# shellcheck disable=SC1091
source ./library_scripts.sh

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update()
{
    echo "Running apt-get update..."
    apt-get update -y
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt_get_update
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

ensure_nanolayer nanolayer_location "v0.5.6"

# Install dependencies
check_packages apt-transport-https curl ca-certificates gnupg python3 wget

# Install Google Key
# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor > /etc/apt/keyrings/cloud.google.gpg
# chmod 644 /etc/apt/keyrings/cloud.google.gpg
# echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
# apt_get_update


echo "Types: deb
URIs: https://packages.cloud.google.com/apt
Suites: cloud-sdk
Components: main
Signed-By:
$(wget -O- https://packages.cloud.google.com/apt/doc/apt-key.gpg | sed -e 's/^$/./' -e 's/^/ /')" >| /etc/apt/sources.list.d/google-cloud-sdk.sources
chmod 644 /etc/apt/sources.list.d/google-cloud-sdk.sources
apt_get_update


declare -A available_packages=(
    ["ANTHOS_AUTH"]="google-cloud-cli-anthos-auth"
    ["APP_ENGINE_GO"]="google-cloud-cli-app-engine-go"
    ["APP_ENGINE_GRPC"]="google-cloud-cli-app-engine-grpc"
    ["APP_ENGINE_JAVA"]="google-cloud-cli-app-engine-java"
    ["APP_ENGINE_PYTHON"]="google-cloud-cli-app-engine-python"
    ["APP_ENGINE_PYTHON_EXTRAS"]="google-cloud-cli-app-engine-python-extras"
    ["BIGTABLE_EMULATOR"]="google-cloud-cli-bigtable-emulator"
    ["CBT"]="google-cloud-cli-cbt"
    ["CLOUD_BUILD_LOCAL"]="google-cloud-cli-cloud-build-local"
    ["CLOUD_RUN_PROXY"]="google-cloud-cli-cloud-run-proxy"
    ["CONFIG_CONNECTOR"]="google-cloud-cli-config-connector"
    ["DATASTORE_EMULATOR"]="google-cloud-cli-datastore-emulator"
    ["FIRESTORE_EMULATOR"]="google-cloud-cli-firestore-emulator"
    ["GKE_GCLOUD_AUTH_PLUGIN"]="google-cloud-cli-gke-gcloud-auth-plugin"
    ["KPT"]="google-cloud-cli-kpt"
    ["KUBECTL_OIDC"]="google-cloud-cli-kubectl-oidc"
    ["LOCAL_EXTRACT"]="google-cloud-cli-local-extract"
    ["MINIKUBE"]="google-cloud-cli-minikube"
    ["NOMOS"]="google-cloud-cli-nomos"
    ["PUBSUB_EMULATOR"]="google-cloud-cli-pubsub-emulator"
    ["SKAFFOLD"]="google-cloud-cli-skaffold"
    ["SPANNER_EMULATOR"]="google-cloud-cli-spanner-emulator"
    ["TERRAFORM_VALIDATOR"]="google-cloud-cli-terraform-validator"
    ["TESTS"]="google-cloud-cli-tests"
)

# Define the packages array
VERSION=${VERSION/latest/}
packages=("google-cloud-cli${VERSION:+"=${VERSION}-0"}")

for key in "${!available_packages[@]}"; do
    if [ "${!key}" == "true" ]; then
        packages+=("${available_packages[$key]}")
    fi
done

printf -v PACKAGES '%s,' "${packages[@]}"

# shellcheck disable=SC2154
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-contrib/features/apt-get-packages:1.0.4" \
        --option packages="${PACKAGES%,}"

echo "Done!"
