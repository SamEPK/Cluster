# LottoTi — Cluster Kubernetes (k3s)

> Projet final ESGI — Clusterisation de containers
> Application LottoTi (Next.js + Flask + PostgreSQL + Redis) déployée sur cluster k3s
> 1 master + 2 workers, persistance Longhorn, HTTPS via cert-manager, Ingress Traefik.

---

## Sommaire

1. [Architecture](#1-architecture)
2. [Pré-requis](#2-pré-requis)
3. [Installation rapide (one-shot)](#3-installation-rapide-one-shot)
4. [Installation pas-à-pas](#4-installation-pas-à-pas)
5. [Vérifications & tests HA](#5-vérifications--tests-ha)
6. [Bonus implémentés](#6-bonus-implémentés)
7. [Structure du dépôt](#7-structure-du-dépôt)
8. [Captures attendues (rendu)](#8-captures-attendues-rendu)
9. [Teardown](#9-teardown)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Architecture

```
                    Internet / Hôte
                          │
                          ▼
              ┌───────────────────────┐
              │  /etc/hosts           │
              │  lottoti.local → master│
              └───────────────────────┘
                          │
        ┌─────────────────┴──────────────────┐
        │  Cluster k3s (Multipass VMs)        │
        │                                     │
        │  ┌─────────────┐                    │
        │  │   master    │ k3s server         │
        │  │  10.x.x.10  │ (control plane)    │
        │  └─────────────┘                    │
        │         │ NodePort 30080/30443      │
        │         ▼                           │
        │  ┌─────────────────────────┐        │
        │  │  Traefik Ingress (k8s)  │ ← HTTPS via cert-manager (CA local)
        │  └────┬─────────────┬──────┘        │
        │       │             │               │
        │       │  /api/*     │  /            │
        │       ▼             ▼               │
        │  ┌────────┐    ┌───────────┐        │
        │  │backend │    │ frontend  │        │
        │  │Flask×2 │    │ Next.js×3 │        │
        │  └────┬───┘    └───────────┘        │
        │       │                             │
        │       ├──────► postgres-0 (RWO 5Gi) │ Longhorn
        │       └──────► redis-0 (RWO 1Gi)    │ Longhorn
        │       └──────► uploads (RWX 5Gi)    │ Longhorn (partage entre les 2 backends)
        │                                     │
        │  ┌─────────────┐  ┌─────────────┐   │
        │  │   worker1   │  │   worker2   │   │
        │  │  app+storage│  │  app+storage│   │
        │  └─────────────┘  └─────────────┘   │
        └─────────────────────────────────────┘
```

### Composants

| Tier         | Workload                  | Replicas | Resources req/lim         | Storage             |
|--------------|---------------------------|----------|---------------------------|---------------------|
| Frontend     | Next.js standalone:3000   | **3**    | 100m/500m CPU · 192Mi/384Mi | —                  |
| Backend      | Flask + Gunicorn-gevent:5000 | **2** | 200m/1 CPU · 384Mi/768Mi  | uploads (RWX 5Gi)   |
| Database     | PostgreSQL 16:5432         | 1        | 200m/1 CPU · 512Mi/1Gi    | pgdata (RWO 5Gi)    |
| Cache        | Redis 7:6379               | 1        | 50m/250m CPU · 64Mi/192Mi | redisdata (RWO 1Gi) |
| Ingress      | Traefik v3                 | 1        | (chart)                   | —                   |
| TLS          | cert-manager (CA local)    | 1        | (chart)                   | —                   |
| Storage      | Longhorn (RWO + RWX)       | DS       | (chart)                   | —                   |

### Flux réseau

```
HTTPS:443 (NodePort 30443)
  → Traefik (entrypoint websecure)
    → /api/health   → backend (rate-limit health)
    → /api/auth/*   → backend (rate-limit strict)
    → /api/*        → backend (rate-limit api)
    → /socket.io/*  → backend (WebSocket sticky session)
    → /*            → frontend (Next.js SSR)

Backend → postgres:5432, redis:6379
Backend → Stripe (egress 443), Sentry (egress 443) via NetworkPolicy
```

---

## 2. Pré-requis

### Sur la machine hôte

| Outil      | Version min | Vérification                  |
|------------|-------------|-------------------------------|
| Multipass  | 1.13+       | `multipass version`           |
| Docker     | 20+         | `docker --version`            |
| kubectl    | 1.28+       | `kubectl version --client`    |
| Helm       | 3.14+       | `helm version`                |
| openssl    | n'importe   | `openssl version`             |
| bash       | 4+          | `bash --version`              |

> **Windows** : utilisez **Git Bash** ou **WSL2** pour les scripts. Multipass et Docker Desktop fonctionnent nativement.

### Source LottoTi

Le code de l'application est attendu à `../LottoTi/` (sibling du dossier `cluster`). Sinon, override avec :
```bash
export LOTTOTI_SRC=/chemin/vers/LottoTi
```

### Ressources matérielles minimales

- **6 vCPU** (2 par VM × 3 VMs)
- **8 Go RAM** (2+3+3 Go)
- **60 Go disque libre**

---

## 3. Installation rapide (one-shot)

```bash
cd cluster/scripts
chmod +x *.sh
./install-all.sh             # cree VMs + k3s + storage + cert-manager + ingress + build + deploy
```

Durée : **~15 minutes** (incluant download images Docker + Longhorn).

À la fin :

```bash
# Ajoute au /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
<MASTER_IP>  lottoti.local  api.lottoti.local

# Acces
https://lottoti.local:30443/
```

---

## 4. Installation pas-à-pas

### 4.1 Création des VMs

```bash
./scripts/01-create-vms.sh
multipass list
# Doit afficher master, worker1, worker2 en Running
```

### 4.2 Installation k3s

```bash
./scripts/02-install-k3s.sh
export KUBECONFIG=$HOME/.kube/config-lottoti
kubectl get nodes -o wide
# 3 nodes Ready
```

> Le master est installé avec `--disable=traefik` car on déploie nous-mêmes Traefik via Helm pour avoir le contrôle de la version et de la config TLS.

### 4.3 Storage : Longhorn

```bash
./scripts/03-install-storage.sh
kubectl -n longhorn-system get pods
kubectl get sc
# longhorn (default) | longhorn driver
```

> **Pourquoi Longhorn ?** Le backend a 2 replicas et doit partager `/app/uploads`. Longhorn supporte **ReadWriteMany** nativement (via NFS provisionner intégré). `local-path` (fourni par k3s) ne supporte que RWO et n'est pas suffisant.

### 4.4 cert-manager + CA local

```bash
./scripts/04-install-cert-manager.sh
kubectl -n cert-manager get pods
kubectl get clusterissuer
# selfsigned-bootstrap (Ready) | lottoti-ca-issuer (Ready)
```

### 4.5 Ingress Traefik

```bash
./scripts/05-install-ingress.sh
kubectl -n traefik get svc
# traefik NodePort 80:30080/TCP, 443:30443/TCP
```

### 4.6 Build & import des images LottoTi

```bash
export LOTTOTI_SRC=../LottoTi   # ou le chemin absolu
./scripts/06-build-images.sh
multipass exec master -- sudo k3s ctr images ls | grep lottoti
# lottoti/backend:1.0.0
# lottoti/frontend:1.0.0
```

### 4.7 Déploiement de LottoTi

```bash
./scripts/07-deploy.sh
kubectl -n lottoti get all
kubectl -n lottoti get ingress,certificate,pvc
```

### 4.8 Accès

Récupère l'IP du master et ajoute au fichier hosts :

```bash
multipass info master | grep IPv4
# IPv4: 10.211.55.10
```

```
# /etc/hosts
10.211.55.10  lottoti.local  api.lottoti.local
```

Puis :
```
https://lottoti.local:30443/
https://api.lottoti.local:30443/api/health
```

> Le navigateur va alerter sur le certificat (CA local non reconnue). Tu peux soit :
> - Importer la CA dans ton trust store (`kubectl -n cert-manager get secret lottoti-ca-key-pair -o jsonpath='{.data.tls\.crt}' | base64 -d > lottoti-ca.crt`)
> - Cliquer "Avancé > Continuer" en dev

---

## 5. Vérifications & tests HA

### 5.1 Cluster healthy

```bash
kubectl get nodes -o wide
kubectl -n lottoti get all
kubectl -n lottoti get pods -o wide   # repartition sur les workers
```

### 5.2 Tests automatisés

```bash
./scripts/08-test-ha.sh
```

Ce script execute :
1. Etat initial du cluster
2. Scale-up backend 2 → 5
3. Kill d'un pod backend → verification recovery
4. Kill du pod postgres-0 → verification persistance des donnees
5. Rolling update frontend
6. Scale-down backend 5 → 2
7. Verification HPA
8. cURL frontend + API health

Captures texte sauvees dans `docs/captures/output/`.

### 5.3 Tests manuels recommandés (pour les screenshots)

Voir [docs/captures/](docs/captures/) — un fichier markdown par test, avec commande exacte et zone screenshot.

| Capture                             | Commande                                            |
|-------------------------------------|-----------------------------------------------------|
| 01-cluster-healthy.md               | `kubectl get nodes -o wide`                          |
| 02-namespaces-pods.md               | `kubectl -n lottoti get pods -o wide`                |
| 03-pvc-pv.md                        | `kubectl -n lottoti get pvc`                         |
| 04-ingress-tls.md                   | `kubectl -n lottoti get ingress,certificate`         |
| 05-scale-up-backend.md              | `kubectl -n lottoti scale deploy/backend --replicas=5` |
| 06-kill-pod-recovery.md             | `kubectl -n lottoti delete pod <backend-pod>`         |
| 07-kill-db-persistence.md           | `kubectl -n lottoti delete pod postgres-0`            |
| 08-rolling-update.md                | `kubectl -n lottoti rollout restart deploy/frontend`  |
| 09-rollback.md                      | `kubectl -n lottoti rollout undo deploy/frontend`     |
| 10-https-access.md                  | navigateur + DevTools                                |
| 11-hpa-load.md                      | `hey -z 60s https://lottoti.local:30443/api/health`   |
| 12-network-policy-blocked.md        | `kubectl exec ... → curl postgres:5432 → BLOCKED`     |

---

## 6. Bonus implémentés

| # | Bonus                                | Localisation                                       | Sujet PDF |
|---|--------------------------------------|----------------------------------------------------|-----------|
| 1 | **Resource Requests & Limits + QoS** | tous les Deployments/StatefulSets (`resources:`)   | bonus 1   |
| 2 | **Node Affinity / Taints**           | postgres + redis pinnés `storage=true`             | bonus 2   |
| 3 | **NetworkPolicy** (zero-trust)       | `k8s/base/60-policies/` (default-deny + allow)     | bonus 3   |
| 4 | **Rolling Update + Rollback auto**   | `strategy.rollingUpdate` + workflow CI rollback    | bonus 4 + 7 |
| 5 | **Autoscaling horizontal (HPA)**     | `30-backend/hpa.yaml` + `40-frontend/hpa.yaml`     | bonus 5   |
| 6 | **CI/CD GitHub Actions**             | `.github/workflows/ci-cd.yml`                      | bonus 6   |
| 7 | **Helm Chart paramétrable**          | `charts/lottoti/`                                  | bonus 8   |

> **7 bonus implémentés**, plafonnés à **+5 points** par le barème.
> **Note potentielle : 20/15** si la doc + captures + démos sont propres.

### Détails

#### Resource Requests & Limits + QoS Burstable
Tous les pods déclarent `requests` et `limits` distincts → QoS class **Burstable**. Cela permet l'éviction propre sous pression mémoire et l'utilisation de l'HPA.

Vérifier :
```bash
kubectl -n lottoti get pod backend-xxx -o jsonpath='{.status.qosClass}'
# Burstable
```

#### Node Affinity
Postgres et Redis sont contraints à un nœud labelisé `storage=true` (worker1/worker2). Cela garantit que leurs PVC restent attachables.
Backend et Frontend ont une **préférence** (`preferredDuringScheduling...`) pour les nœuds `lottoti.io/role=app` mais peuvent floater. PodAntiAffinity les répartit entre nœuds.

#### NetworkPolicy zero-trust
- `default-deny-all` bloque tout (ingress + egress) dans le namespace `lottoti`.
- `allow-dns` ouvre uniquement le DNS vers kube-system.
- Chaque tier a sa policy explicite (frontend ⇄ backend, backend ⇄ postgres/redis, egress externe pour Stripe/Sentry).

Test : depuis un pod frontend, essayer de joindre postgres directement → bloqué :
```bash
kubectl -n lottoti exec deploy/frontend -- nc -vz postgres 5432
# Connection timed out (la NetworkPolicy bloque)
```

#### HPA (Autoscaling)
Backend : `minReplicas=2, maxReplicas=8`, scaling sur CPU > 70 % et mémoire > 80 %.
Frontend : `minReplicas=3, maxReplicas=10`, scaling sur CPU > 75 %.

Test load :
```bash
kubectl run -n lottoti load --image=ghcr.io/six-ddc/plow:v1.4.0 --rm -i --tty -- \
  -c 50 -d 60s https://backend:5000/api/health
kubectl -n lottoti get hpa -w
```

#### Rolling Update + Rollback automatique
- `maxSurge: 1, maxUnavailable: 0` → zero-downtime.
- En CI : `kubectl rollout status` avec `--timeout` puis `rollout undo` en cas d'echec.

#### CI/CD
3 jobs : `lint-k8s` (kubeconform), `lint-helm` (helm lint + template), `build-images` (push GHCR), `deploy` (manual ou tag, kubectl apply -k).

#### Helm Chart
Tout le déploiement est paramétrable via `charts/lottoti/values.yaml`. Permet :
- Alternance dev/staging/prod via valeurs différentes
- Multi-tenant (plusieurs LottoTi sur le même cluster, namespaces différents)
- Upgrade + rollback Helm-natif

```bash
helm install lottoti charts/lottoti -n lottoti \
  --set secrets.createSecret=true \
  --set secrets.postgresPassword=$(openssl rand -hex 24) \
  --set secrets.flaskSecretKey=$(openssl rand -hex 32) \
  --set secrets.jwtSecretKey=$(openssl rand -hex 32)
```

---

## 7. Structure du dépôt

```
cluster/
├── README.md                           # ce fichier
├── ARCHITECTURE.md                     # diagrammes + flux réseau détaillé
├── scripts/                            # 9 scripts shell idempotents
│   ├── 00-vars.sh                      # config partagée
│   ├── 01-create-vms.sh                # Multipass × 3
│   ├── 02-install-k3s.sh               # k3s server + agents
│   ├── 03-install-storage.sh           # Longhorn (RWX)
│   ├── 04-install-cert-manager.sh      # cert-manager + CA
│   ├── 05-install-ingress.sh           # Traefik v3
│   ├── 06-build-images.sh              # docker build + ctr import
│   ├── 07-deploy.sh                    # kustomize + secrets
│   ├── 08-test-ha.sh                   # tests HA + captures
│   ├── 99-teardown.sh                  # cleanup VMs
│   └── install-all.sh                  # one-shot
├── k8s/                                # Manifests Kubernetes (Kustomize)
│   ├── base/
│   │   ├── 00-namespaces/              # Namespace lottoti
│   │   ├── 15-cert-manager/            # Issuers (CA local)
│   │   ├── 20-database/                # Postgres StatefulSet
│   │   ├── 25-redis/                   # Redis StatefulSet
│   │   ├── 30-backend/                 # Flask Deployment + HPA + PDB + PVC RWX
│   │   ├── 40-frontend/                # Next.js Deployment + HPA + PDB
│   │   ├── 50-ingress/                 # Traefik Ingress + Certificate
│   │   ├── 60-policies/                # NetworkPolicies (zero-trust)
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/                        # 1 replica, HPA reduit
│       └── prod/                       # 2/3 replicas, HPA full
├── charts/lottoti/                     # Helm chart equivalent (bonus)
├── .github/workflows/ci-cd.yml         # CI/CD GitHub Actions (bonus)
└── docs/
    ├── captures/                       # README + zones screenshot par test
    │   └── output/                     # captures texte auto-generees
    └── diagrams/                       # diagrammes archi (mermaid + svg)
```

---

## 8. Captures attendues (rendu)

Voir [docs/captures/INDEX.md](docs/captures/INDEX.md) — chaque test a son propre fichier markdown avec :

- 📋 **Commande exacte** à lancer
- 📸 **Zone screenshot** (capture d'écran à coller)
- ✅ **Résultat attendu**
- 🎯 **Critère du barème** validé

---

## 9. Teardown

```bash
./scripts/99-teardown.sh
```

Supprime les 3 VMs Multipass, le kubeconfig, les .tar des images.

---

## 10. Troubleshooting

### Pod backend en CrashLoopBackOff

```bash
kubectl -n lottoti logs deploy/backend --tail=50
# Souvent: DATABASE_URL invalide. Verifier le Secret POSTGRES_PASSWORD.
kubectl -n lottoti get secret lottoti-secrets -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### Certificate "Not Ready"

```bash
kubectl -n lottoti describe certificate lottoti-tls
kubectl -n cert-manager logs deploy/cert-manager --tail=50
```

### PVC "Pending"

```bash
kubectl -n lottoti get pvc
kubectl -n longhorn-system get volumes,replicas
# Souvent: aucun noeud ne supporte le mode RWX. Verifier que tous les noeuds ont open-iscsi installe.
```

### Ingress 404

```bash
kubectl -n traefik logs deploy/traefik --tail=50
# Verifier que l'IngressRoute est bien charge:
kubectl -n lottoti get ingressroute,ingress
```

### "no such host: postgres"

NetworkPolicy + DNS : assure-toi que `allow-dns` est bien appliquee :
```bash
kubectl -n lottoti get networkpolicy
```

### Reset complet

```bash
./scripts/99-teardown.sh
./scripts/install-all.sh
```

---

## Auteurs

Projet réalisé dans le cadre du module **Clusterisation de containers** — ESGI 4ème année.
Application LottoTi : projet annuel.

## Licence

Internal / Educational — usage hors cours interdit sans accord.
