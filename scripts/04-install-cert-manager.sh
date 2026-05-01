#!/usr/bin/env bash
# ============================================================
# 04 - Installe cert-manager + ClusterIssuer auto-signe
# Genere le CA local utilise par l'Ingress pour HTTPS lottoti.local
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-lottoti}"

CM_VERSION="v1.16.2"

log "Installation cert-manager $CM_VERSION"
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/$CM_VERSION/cert-manager.yaml"

log "Attente cert-manager ready..."
kubectl -n cert-manager wait --for=condition=Available deploy --all --timeout=5m
kubectl -n cert-manager get pods

log "Application des Issuers (selfsigned + CA)"
kubectl apply -f "$SCRIPT_DIR/../k8s/base/15-cert-manager/00-selfsigned-issuer.yaml"
kubectl apply -f "$SCRIPT_DIR/../k8s/base/15-cert-manager/01-ca-certificate.yaml"

log "Attente generation du Certificate CA..."
kubectl -n cert-manager wait --for=condition=Ready certificate/lottoti-ca --timeout=2m

kubectl apply -f "$SCRIPT_DIR/../k8s/base/15-cert-manager/02-ca-issuer.yaml"

ok "cert-manager pret. ClusterIssuer 'lottoti-ca-issuer' disponible."
log "Etape suivante: ./05-install-ingress.sh"
