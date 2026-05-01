#!/usr/bin/env bash
# ============================================================
# install-all - One-shot pour rebuild un cluster from scratch
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/01-create-vms.sh"
bash "$SCRIPT_DIR/02-install-k3s.sh"
bash "$SCRIPT_DIR/03-install-storage.sh"
bash "$SCRIPT_DIR/04-install-cert-manager.sh"
bash "$SCRIPT_DIR/05-install-ingress.sh"
bash "$SCRIPT_DIR/06-build-images.sh"
bash "$SCRIPT_DIR/07-deploy.sh"
echo "[OK] Cluster + LottoTi prets. Lance ./08-test-ha.sh pour les tests."
