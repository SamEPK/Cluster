#!/usr/bin/env bash
# ============================================================
# 99 - Teardown: detruit les VMs et nettoie kubeconfig
# Idempotent.
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

if command -v multipass >/dev/null 2>&1; then
    for n in master worker1 worker2; do
        if multipass info "$n" >/dev/null 2>&1; then
            log "Suppression VM $n"
            multipass delete "$n"
        fi
    done
    multipass purge || true
fi

rm -f "$HOME/.kube/config-lottoti" "$K3S_TOKEN_FILE"
rm -rf "$SCRIPT_DIR/.images"
ok "Teardown complet."
