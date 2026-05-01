#!/usr/bin/env bash
# ============================================================
# 01 - Cree 1 master + 2 workers via Multipass
# Pre-requis: multipass installe (https://multipass.run)
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

if ! command -v multipass >/dev/null 2>&1; then
    err "multipass introuvable. Installe-le: https://multipass.run/install"
    err "Alternative: utilise un autre provisioner et lance directement 02-install-k3s.sh sur tes 3 hotes."
    exit 1
fi

create_vm() {
    local name="$1" mem="$2"
    if multipass info "$name" >/dev/null 2>&1; then
        warn "VM $name existe deja, on saute la creation."
        return 0
    fi
    log "Creation VM $name (cpus=$VM_CPUS mem=$mem disk=$VM_DISK)"
    multipass launch "$VM_IMAGE" \
        --name "$name" \
        --cpus "$VM_CPUS" \
        --memory "$mem" \
        --disk "$VM_DISK"
    ok "VM $name lancee"
}

log "=== Creation VMs cluster $CLUSTER_NAME ==="
create_vm "master" "$VM_MEM_MASTER"
for w in "${NODES_WORKERS[@]}"; do
    create_vm "$w" "$VM_MEM_WORKER"
done

log "Etat VMs:"
multipass list

ok "Toutes les VMs sont up. Etape suivante: ./02-install-k3s.sh"
