#!/usr/bin/env bash
# ============================================================
# 06 - Build des images LottoTi + import sur chaque noeud k3s
# Source code: $LOTTOTI_SRC (par defaut: ../LottoTi sibling)
#
# Strategie: build local avec docker, save en tar, ctr import sur chaque
# noeud. Pas de registry externe necessaire.
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/00-vars.sh"

if [[ ! -d "$LOTTOTI_SRC" ]]; then
    err "Source LottoTi introuvable: $LOTTOTI_SRC"
    err "Definis LOTTOTI_SRC=/chemin/vers/LottoTi puis relance."
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    err "Docker requis pour le build. Installe docker desktop ou docker engine."
    exit 1
fi

WORK="$SCRIPT_DIR/.images"
mkdir -p "$WORK"

build_and_save() {
    local name="$1" path="$2" extra_args="${3:-}"
    local image="lottoti/${name}:${APP_IMAGE_TAG}"
    log "Build $image depuis $path"
    # shellcheck disable=SC2086
    docker build -t "$image" $extra_args "$path"
    log "Save $image -> $WORK/${name}.tar"
    docker save -o "$WORK/${name}.tar" "$image"
    ok "$image pret"
}

log "=== Build images ==="
build_and_save "backend"  "$LOTTOTI_SRC/backend"
build_and_save "frontend" "$LOTTOTI_SRC/lottoit" "--build-arg NEXT_PUBLIC_API_URL=https://api.${APP_DOMAIN} --build-arg NEXT_PUBLIC_SOCKET_URL=https://api.${APP_DOMAIN}"

# nginx custom non requis (Traefik fait le job d'Ingress)
# Mais on prepare un nginx-static pour servir /uploads si besoin (option B)

log "=== Import sur chaque noeud k3s ==="
for n in master worker1 worker2; do
    for img in backend frontend; do
        log "Transfert $img -> $n"
        multipass transfer "$WORK/${img}.tar" "$n:/tmp/${img}.tar"
        log "Import $img sur $n"
        multipass exec "$n" -- bash -lc "sudo k3s ctr images import /tmp/${img}.tar && rm /tmp/${img}.tar"
    done
done

log "Verification images sur master:"
multipass exec master -- bash -lc 'sudo k3s ctr images ls | grep lottoti || true'

ok "Images pretes. Etape suivante: ./07-deploy.sh"
