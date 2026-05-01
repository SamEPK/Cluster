#!/usr/bin/env bash
# ============================================================
# 07 - Deploie LottoTi via Kustomize (overlay prod par defaut)
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-lottoti}"
OVERLAY="${OVERLAY:-prod}"

# --- Generation des secrets si .env n'existe pas ---
SECRETS_ENV="$SCRIPT_DIR/.secrets.env"
if [[ ! -f "$SECRETS_ENV" ]]; then
    log "Generation des secrets ($SECRETS_ENV) - 1ere fois"
    cat > "$SECRETS_ENV" <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 24)
FLASK_SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
STRIPE_SECRET_KEY=sk_test_PLACEHOLDER_remplace_par_ta_cle
STRIPE_WEBHOOK_SECRET=whsec_PLACEHOLDER_remplace_par_ta_cle
EOF
    chmod 600 "$SECRETS_ENV"
    warn "Secrets generes dans $SECRETS_ENV - mets-y tes vraies cles Stripe avant deploiement reel."
fi

# --- Creation Secret Kubernetes a la volee ---
log "Application namespaces"
kubectl apply -f "$SCRIPT_DIR/../k8s/base/00-namespaces/"

log "Creation Secret 'lottoti-secrets' depuis $SECRETS_ENV"
kubectl -n "$APP_NAMESPACE" create secret generic lottoti-secrets \
    --from-env-file="$SECRETS_ENV" \
    --dry-run=client -o yaml | kubectl apply -f -

# --- Application Kustomize ---
log "Application overlay '$OVERLAY'"
kubectl apply -k "$SCRIPT_DIR/../k8s/overlays/$OVERLAY"

log "=== Attente rollout (jusqu'a 5 min) ==="
kubectl -n "$APP_NAMESPACE" rollout status statefulset/postgres --timeout=5m
kubectl -n "$APP_NAMESPACE" rollout status statefulset/redis --timeout=5m
kubectl -n "$APP_NAMESPACE" rollout status deploy/backend --timeout=5m
kubectl -n "$APP_NAMESPACE" rollout status deploy/frontend --timeout=5m

log "Etat final:"
kubectl -n "$APP_NAMESPACE" get all
echo
kubectl -n "$APP_NAMESPACE" get ingress

MASTER_IP="$(multipass info master 2>/dev/null | awk '/IPv4/ {print $2; exit}' || echo 'INCONNU')"

cat <<EOF

${C_GREEN}=== Deploiement reussi ===${C_RESET}

URL: https://$APP_DOMAIN (NodePort 30443) ou http://$APP_DOMAIN (NodePort 30080)
API: https://api.$APP_DOMAIN

Pour acceder, ajoute a /etc/hosts (ou C:\\Windows\\System32\\drivers\\etc\\hosts):
    $MASTER_IP $APP_DOMAIN api.$APP_DOMAIN

Tests HA: ./08-test-ha.sh
Teardown: ./99-teardown.sh
EOF
