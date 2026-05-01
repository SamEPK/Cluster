#!/usr/bin/env bash
# ============================================================
# 03 - Installe Longhorn (RWX storage pour uploads + DB)
# Necessaire pour la persistance + replicas backend (RWX).
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-lottoti}"

# --- Pre-requis Longhorn (open-iscsi sur chaque noeud) ---
log "Installation prerequis Longhorn (open-iscsi, nfs-common) sur tous les noeuds"
for n in master worker1 worker2; do
    multipass exec "$n" -- bash -lc "
        sudo apt-get update -qq
        sudo apt-get install -y -qq open-iscsi nfs-common util-linux
        sudo systemctl enable --now iscsid
    " &
done
wait
ok "Prerequis installes"

# --- Helm ---
if ! command -v helm >/dev/null 2>&1; then
    log "Installation Helm sur la machine locale"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# --- Longhorn via Helm ---
log "Ajout repo Helm Longhorn"
helm repo add longhorn https://charts.longhorn.io
helm repo update

log "Installation Longhorn (peut prendre 3-5 min)"
helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system --create-namespace \
    --version 1.7.2 \
    --set defaultSettings.defaultDataPath="/var/lib/longhorn" \
    --set defaultSettings.replicaSoftAntiAffinity=true \
    --set persistence.defaultClassReplicaCount=2 \
    --wait --timeout 10m

log "Attente Longhorn ready..."
kubectl -n longhorn-system rollout status deploy/longhorn-driver-deployer --timeout=5m
kubectl -n longhorn-system wait --for=condition=Ready pod -l app=longhorn-manager --timeout=5m

# --- Promote longhorn comme StorageClass par defaut ---
log "longhorn devient la StorageClass par defaut"
kubectl annotate storageclass longhorn \
    storageclass.kubernetes.io/is-default-class=true --overwrite || true
kubectl annotate storageclass local-path \
    storageclass.kubernetes.io/is-default-class- --overwrite 2>/dev/null || true

# --- Verif ---
kubectl get sc
ok "Storage pret. Etape suivante: ./04-install-cert-manager.sh"
