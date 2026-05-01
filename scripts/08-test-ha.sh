#!/usr/bin/env bash
# ============================================================
# 08 - Tests Haute Disponibilite + captures texte
# Genere des artefacts dans docs/captures/output/ pour la doc.
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-lottoti}"
OUT="$SCRIPT_DIR/../docs/captures/output"
mkdir -p "$OUT"

run() {
    local name="$1"; shift
    echo
    echo "=== $name ==="
    "$@" 2>&1 | tee "$OUT/${name}.txt"
}

log "[1/8] Etat initial du cluster"
run "01-nodes"       kubectl get nodes -o wide
run "02-all-app"     kubectl -n "$APP_NAMESPACE" get all -o wide
run "03-pvc"         kubectl -n "$APP_NAMESPACE" get pvc

log "[2/8] Test scale-up: backend 2 -> 5"
kubectl -n "$APP_NAMESPACE" scale deploy/backend --replicas=5
sleep 3
run "04-scale-up-backend" kubectl -n "$APP_NAMESPACE" get pods -l app=backend -o wide

log "[3/8] Test kill pod: tuer 1 backend"
TARGET=$(kubectl -n "$APP_NAMESPACE" get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
log "  Cible: $TARGET"
kubectl -n "$APP_NAMESPACE" delete pod "$TARGET" --grace-period=0 --force
sleep 5
run "05-after-kill-backend" kubectl -n "$APP_NAMESPACE" get pods -l app=backend -o wide

log "[4/8] Test kill DB pod: postgres-0"
kubectl -n "$APP_NAMESPACE" delete pod postgres-0 --grace-period=0 --force || true
sleep 10
run "06-after-kill-db" kubectl -n "$APP_NAMESPACE" get pods -l app=postgres -o wide

log "[5/8] Verification persistance DB (les volumes survivent)"
run "07-pvc-after-kill" kubectl -n "$APP_NAMESPACE" get pvc

log "[6/8] Test rolling update: bump frontend image annotation"
kubectl -n "$APP_NAMESPACE" patch deploy/frontend \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"rollout.lottoti/restartedAt\":\"$(date +%s)\"}}}}}"
kubectl -n "$APP_NAMESPACE" rollout status deploy/frontend --timeout=3m
run "08-rolling-history" kubectl -n "$APP_NAMESPACE" rollout history deploy/frontend

log "[7/8] Test scale-down: backend retour a 2"
kubectl -n "$APP_NAMESPACE" scale deploy/backend --replicas=2
sleep 3
run "09-scale-down-backend" kubectl -n "$APP_NAMESPACE" get pods -l app=backend -o wide

log "[8/8] HPA status (si bonus active)"
run "10-hpa" kubectl -n "$APP_NAMESPACE" get hpa

log "=== Verification HTTP via Ingress ==="
MASTER_IP="$(multipass info master 2>/dev/null | awk '/IPv4/ {print $2; exit}' || echo '')"
if [[ -n "$MASTER_IP" ]]; then
    run "11-curl-frontend" curl -sk -o /dev/null -w "HTTP %{http_code} Time:%{time_total}s\n" \
        --resolve "$APP_DOMAIN:30443:$MASTER_IP" \
        "https://$APP_DOMAIN:30443/"
    run "12-curl-api-health" curl -sk \
        --resolve "api.$APP_DOMAIN:30443:$MASTER_IP" \
        "https://api.$APP_DOMAIN:30443/api/health" || true
fi

ok "Tests HA termines. Captures dans: $OUT/"
