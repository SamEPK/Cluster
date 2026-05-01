#!/usr/bin/env bash
# ============================================================
# 05 - Installe Traefik v3 comme Ingress Controller
# (k3s a Traefik integre desactive via --disable=traefik dans 02-)
# On gere notre propre version pour controler la config + TLS.
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-lottoti}"

log "Ajout repo Helm Traefik"
helm repo add traefik https://traefik.github.io/charts
helm repo update

log "Installation Traefik v3"
helm upgrade --install traefik traefik/traefik \
    --namespace traefik --create-namespace \
    --version 33.0.0 \
    --set service.type=NodePort \
    --set "ports.web.nodePort=30080" \
    --set "ports.websecure.nodePort=30443" \
    --set "ingressClass.isDefaultClass=true" \
    --set "ingressClass.name=traefik" \
    --set "providers.kubernetesIngress.allowExternalNameServices=true" \
    --set "providers.kubernetesCRD.allowCrossNamespace=true" \
    --set "logs.access.enabled=true" \
    --wait --timeout 5m

kubectl -n traefik rollout status deploy/traefik --timeout=3m
kubectl -n traefik get svc traefik

MASTER_IP="$(multipass info master 2>/dev/null | awk '/IPv4/ {print $2; exit}' || echo 'INCONNU')"

cat <<EOF

${C_GREEN}=== Traefik installe ===${C_RESET}
NodePorts: http=30080 https=30443
Master IP: $MASTER_IP

Pour acceder via $APP_DOMAIN, ajoute a /etc/hosts (ou C:\\Windows\\System32\\drivers\\etc\\hosts):
    $MASTER_IP $APP_DOMAIN api.$APP_DOMAIN

Etape suivante: ./06-build-images.sh
EOF
