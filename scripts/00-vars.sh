#!/usr/bin/env bash
# ============================================================
# LottoTi Cluster - Variables partagees
# Sourced par tous les autres scripts.
# ============================================================
set -euo pipefail

# --- Topologie cluster ---
export CLUSTER_NAME="${CLUSTER_NAME:-lottoti}"
export NODES_MASTER=("master")
export NODES_WORKERS=("worker1" "worker2")

# --- Multipass (VMs Ubuntu locales) ---
export VM_IMAGE="${VM_IMAGE:-22.04}"          # Ubuntu LTS
export VM_CPUS="${VM_CPUS:-2}"
export VM_MEM_MASTER="${VM_MEM_MASTER:-2G}"
export VM_MEM_WORKER="${VM_MEM_WORKER:-3G}"   # workers hebergent app + storage
export VM_DISK="${VM_DISK:-20G}"

# --- k3s ---
export K3S_VERSION="${K3S_VERSION:-v1.30.6+k3s1}"
export K3S_TOKEN_FILE="${K3S_TOKEN_FILE:-$(dirname "$0")/.k3s-token}"

# --- Application ---
export APP_NAMESPACE="lottoti"
export APP_DOMAIN="${APP_DOMAIN:-lottoti.local}"
export APP_IMAGE_TAG="${APP_IMAGE_TAG:-1.0.0}"

# --- Source LottoTi (sibling directory expected) ---
export LOTTOTI_SRC="${LOTTOTI_SRC:-$(cd "$(dirname "$0")/../.." && pwd)/LottoTi}"

# --- Couleurs log ---
if [[ -t 1 ]]; then
    export C_RESET="\033[0m"
    export C_BLUE="\033[1;34m"
    export C_GREEN="\033[1;32m"
    export C_YELLOW="\033[1;33m"
    export C_RED="\033[1;31m"
else
    export C_RESET="" C_BLUE="" C_GREEN="" C_YELLOW="" C_RED=""
fi

log()  { echo -e "${C_BLUE}[$(date +%H:%M:%S)]${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[ERR]${C_RESET} $*" >&2; }
