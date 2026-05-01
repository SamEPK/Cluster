#!/usr/bin/env bash
# ============================================================
# 02 - Installe k3s server sur master + agents sur workers
# Genere kubeconfig local et token de jonction.
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

mp() { multipass exec "$1" -- bash -lc "$2"; }

# --- IPs ---
log "Resolution IPs des VMs..."
MASTER_IP="$(multipass info master | awk '/IPv4/ {print $2; exit}')"
[[ -n "$MASTER_IP" ]] || { err "Impossible d'obtenir l'IP du master"; exit 1; }
ok "master = $MASTER_IP"

# --- k3s server (master) ---
log "Installation k3s server sur master (version $K3S_VERSION)"
mp master "
    if ! command -v k3s >/dev/null 2>&1; then
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' \
            INSTALL_K3S_EXEC='server --disable=traefik --tls-san=$MASTER_IP --node-name=master' \
            sh -
    else
        echo 'k3s deja installe sur master'
    fi
    sudo systemctl is-active k3s >/dev/null && echo 'k3s actif' || sudo systemctl start k3s
"

# --- Token ---
log "Recuperation du token de jonction"
TOKEN="$(mp master 'sudo cat /var/lib/rancher/k3s/server/node-token')"
echo "$TOKEN" > "$K3S_TOKEN_FILE"
chmod 600 "$K3S_TOKEN_FILE"
ok "Token sauvegarde dans $K3S_TOKEN_FILE"

# --- k3s agents (workers) ---
for w in "${NODES_WORKERS[@]}"; do
    log "Installation k3s agent sur $w"
    mp "$w" "
        if ! command -v k3s >/dev/null 2>&1; then
            curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' \
                K3S_URL='https://$MASTER_IP:6443' \
                K3S_TOKEN='$TOKEN' \
                INSTALL_K3S_EXEC='agent --node-name=$w' \
                sh -
        else
            echo 'k3s deja installe sur $w'
        fi
    "
done

# --- Recuperation kubeconfig ---
log "Recuperation kubeconfig vers ~/.kube/config-lottoti"
mkdir -p "$HOME/.kube"
mp master 'sudo cat /etc/rancher/k3s/k3s.yaml' \
    | sed "s/127.0.0.1/$MASTER_IP/" > "$HOME/.kube/config-lottoti"
chmod 600 "$HOME/.kube/config-lottoti"
ok "kubeconfig: $HOME/.kube/config-lottoti"

# --- Sanity check ---
log "Verification cluster..."
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl wait --for=condition=Ready node --all --timeout=120s
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl get nodes -o wide

# --- Labels workers (utile pour Longhorn + nodeAffinity bonus) ---
log "Labelling workers"
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl label node worker1 storage=true --overwrite
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl label node worker2 storage=true --overwrite
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl label node worker1 lottoti.io/role=app --overwrite
KUBECONFIG="$HOME/.kube/config-lottoti" kubectl label node worker2 lottoti.io/role=app --overwrite

cat <<EOF

${C_GREEN}=== Cluster k3s installe avec succes ===${C_RESET}
Master:    $MASTER_IP
Workers:   ${NODES_WORKERS[*]}
Kubeconfig: $HOME/.kube/config-lottoti

Ajoute a ton shell:
    export KUBECONFIG=\$HOME/.kube/config-lottoti

Etape suivante: ./03-install-storage.sh
EOF
