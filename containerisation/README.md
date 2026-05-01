# Conteneurisation LottoTi (Docker)

> **Etape 1 du projet** : conteneurisation de l'application LottoTi avec Docker
> avant son orchestration sur cluster Kubernetes (voir le dossier parent `k8s/`).
>
> Cette doc explique la stack Docker, les Dockerfiles, le `docker-compose.yml`
> et fait le **mapping** vers les manifests Kubernetes correspondants.

---

## Pourquoi cette etape ?

Le sujet ESGI demande de **conteneuriser** l'application **avant** de l'orchestrer.
LottoTi etait deja conteneurise avec `docker-compose` pour le developpement local
et la production simple. Cette base sert de **point de depart** pour la transition
vers Kubernetes :

```
                    docker-compose.yml
                            |
                            v
            +-------------------------------+
            | 5 services sur 1 seule machine|
            | Pas de HA, pas de scaling     |
            +-------------------------------+
                            |
                            v
                    Migration vers k8s
                            |
                            v
            +-------------------------------+
            | 5+ services sur 3 noeuds      |
            | Replicas, HPA, NetworkPolicy  |
            | Persistance via PV/PVC        |
            +-------------------------------+
```

---

## Structure du dossier

```
containerisation/
├── README.md                       <-- ce fichier
├── docker-compose.yml              <-- orchestration locale (5 services)
├── .env.example                    <-- variables d'environnement (template)
│
├── backend/
│   ├── Dockerfile                  <-- multi-stage Python 3.12 + Flask
│   ├── docker-entrypoint.sh        <-- script de boot (wait DB + migrations)
│   ├── gunicorn.conf.py            <-- config serveur WSGI prod
│   └── requirements.txt            <-- deps Python
│
├── frontend/
│   └── Dockerfile                  <-- multi-stage Node 20 + Next.js standalone
│
└── nginx/
    └── nginx.conf                  <-- reverse proxy + rate limiting + WebSocket
```

---

## La stack en un coup d'oeil

| Service | Image / Build | Role | Port | Volume |
|---|---|---|---|---|
| `frontend` | build local Next.js | UI React | 3000 | - |
| `api` | build local Flask | Backend + WebSocket | 5000 | uploads, logs |
| `db` | `postgres:16-alpine` | BDD | 5432 | pgdata |
| `redis` | `redis:7-alpine` | Cache + sessions | 6379 | redisdata |
| `nginx` | `nginx:1.25-alpine` | Reverse proxy | 80 / 443 | uploads (RO) |

---

## Concepts cles

### 1. Multi-stage build (backend + frontend)

Les deux Dockerfiles utilisent du multi-stage pour produire des images **petites et securisees** :

| Image | Avec multi-stage | Sans multi-stage (estim.) |
|---|---|---|
| `lottoti/backend:1.0.0` | **252 MB** | ~600 MB |
| `lottoti/frontend:1.0.0` | **216 MB** | ~1 GB |

**Principe** : la stage "builder" contient les compilateurs (gcc, npm devDeps).
La stage "runtime" ne garde que les binaires/packages compiles. Resultat : image
finale 50-70% plus petite.

### 2. Utilisateur non-root

Les deux Dockerfiles creent un utilisateur dedie (`lottoit` / `nextjs`) et
font `USER` avant le `CMD`. Si une faille est exploitee dans Flask ou Next.js,
l'attaquant n'aura **PAS** les droits root du conteneur.

### 3. Healthchecks

Chaque service a son healthcheck dans le compose :

| Service | Test |
|---|---|
| `api` | `curl http://localhost:5000/api/health` |
| `frontend` | `node -e "fetch('http://localhost:3000/')..."` (alpine n'a pas curl) |
| `db` | `pg_isready -U lottoit` |
| `redis` | `redis-cli ping` |

Permet a Docker de savoir **quand** le service est vraiment Ready, pas juste demarre.

### 4. Networks isoles

```yaml
networks:
  app:
    driver: bridge
```

**Tous** les services sont sur le meme network `app`. Resolution DNS automatique :
le backend joint la DB via `db:5432`, pas une IP. Seul `nginx` expose des ports
vers l'hote (80, 443) - les autres sont **invisibles** depuis l'exterieur.

### 5. Volumes nommes (persistance)

```yaml
volumes:
  pgdata:    {driver: local}    # data Postgres
  redisdata: {driver: local}    # data Redis (AOF)
  uploads:   {driver: local}    # photos vehicules upload utilisateurs
  logs:      {driver: local}    # logs Flask
```

Sans ces volumes, `docker-compose down` = toutes les donnees perdues. Les volumes
nommes sont stockes par Docker en dehors des conteneurs.

### 6. Cascade de dependances

```yaml
api:
  depends_on:
    db:    {condition: service_healthy}
    redis: {condition: service_healthy}
```

Le backend ne demarre **qu'apres** que la DB et Redis soient sains. Evite les
crashloop au demarrage de la stack.

### 7. Reverse proxy nginx (single entry point)

Toutes les requetes passent par nginx (port 80 ou 443) :

```
/api/auth/*    -> backend (rate limit 5 req/s, anti-bruteforce login)
/api/health    -> backend (rate limit 1 req/s)
/api/*         -> backend (rate limit 30 req/s)
/socket.io/*   -> backend WebSocket
/uploads/*     -> serveur de fichiers (cache 30j)
/_next/static  -> frontend (cache 1 an)
/*             -> frontend Next.js
```

Plus security headers (X-Frame-Options DENY, X-Content-Type-Options nosniff, CSP, ...).

### 8. Variables d'environnement (Secrets vs Config)

```bash
# .env (a NE PAS commiter, voir .env.example pour le template)

# SENSIBLES
FLASK_SECRET_KEY=<openssl rand -hex 32>
JWT_SECRET_KEY=<openssl rand -hex 32>
POSTGRES_PASSWORD=<openssl rand -hex 32>
STRIPE_SECRET_KEY=sk_test_...

# CONFIG (non sensible)
FLASK_ENV=production
LOG_LEVEL=info
FRONTEND_URL=http://localhost
```

**Limite** : `.env` est en clair sur le filesystem. C'est OK pour du dev/staging.
En prod cluster, on passe a **Kubernetes Secrets** chiffres dans etcd.

---

## Workflow Docker classique

```bash
# 1. Copier le template d'env
cp .env.example .env
# editer .env avec les vraies valeurs

# 2. Build des images (frontend + backend)
docker-compose build

# 3. Lancer la stack
docker-compose up -d

# 4. Verifier
docker-compose ps
# NAME             STATUS              PORTS
# lottoit-frontend Up (healthy)        3000/tcp
# lottoit-api      Up (healthy)        5000/tcp
# lottoit-db       Up (healthy)        5432/tcp
# lottoit-redis    Up (healthy)        6379/tcp
# lottoit-nginx    Up                  0.0.0.0:80->80/tcp

# 5. Acceder a l'app
curl http://localhost/api/health
# {"checks":{"database":{"status":"healthy"}},"status":"healthy","version":"1.0.0"}

# 6. Logs
docker-compose logs -f api

# 7. Stop
docker-compose down              # garde les volumes
docker-compose down -v           # ATTENTION: supprime aussi les volumes (data perdue)
```

---

## Mapping Docker -> Kubernetes

Cette base Docker est **portee** vers Kubernetes dans le dossier `k8s/`. Voici
la correspondance directe :

| Concept Docker | Equivalent Kubernetes | Fichier k8s |
|---|---|---|
| Service compose `api` | `Deployment` + `Service` | `k8s/base/30-backend/` |
| Service compose `frontend` | `Deployment` + `Service` | `k8s/base/40-frontend/` |
| Service compose `db` | `StatefulSet` + `Service` (headless) | `k8s/base/20-database/` |
| Service compose `redis` | `StatefulSet` + `Service` | `k8s/base/25-redis/` |
| Service compose `nginx` | `Ingress` (Traefik) + `Middlewares` | `k8s/base/50-ingress/` |
| `restart: unless-stopped` | `restartPolicy: Always` (par defaut Deployment) | dans chaque Deployment |
| `healthcheck` | `livenessProbe` + `readinessProbe` + `startupProbe` | dans chaque container spec |
| `networks: app` | `NetworkPolicy` (zero-trust) | `k8s/base/60-policies/` |
| `volumes:` (named) | `PersistentVolumeClaim` | `k8s/base/30-backend/pvc-uploads.yaml` + StatefulSet `volumeClaimTemplates` |
| `.env` / `env_file:` | `Secret` (sensibles) + `ConfigMap` (non-sensibles) | `lottoti-secrets`, `backend-config`, `postgres-config` |
| `depends_on:` | `initContainers` (`wait-for-db`, `wait-for-redis`) | `k8s/base/30-backend/deployment.yaml` |
| `expose: 80` (nginx) | `Ingress` + cert-manager TLS | `k8s/base/50-ingress/ingress.yaml` |

### Gains apportes par Kubernetes (vs docker-compose)

| Besoin | docker-compose | Kubernetes |
|---|---|---|
| **Haute dispo** | 1 instance par service | `replicas: 2` (backend), `replicas: 3` (frontend) |
| **Scaling auto** | Non | `HorizontalPodAutoscaler` sur CPU + memory |
| **Multi-host** | Non | 3 nodes (1 master + 2 workers) |
| **Auto-healing** | `restart: unless-stopped` | Replanification automatique sur autre noeud si node down |
| **Rolling update** | Downtime | `maxUnavailable: 0` zero-downtime |
| **Rollback** | Manuel | `kubectl rollout undo` |
| **Secrets chiffres** | `.env` en clair | etcd encryption at rest |
| **Reseau zero-trust** | Non | 8 NetworkPolicies |
| **TLS automatique** | Manuel | cert-manager + Let's Encrypt ou CA local |
| **Documentation a la code** | docker-compose.yml | 36 manifests Kustomize |

---

## Pour la soutenance

Le pred peut demander a voir l'etat **avant Kubernetes**. Ce dossier sert
de reference :

1. **Ouvrir `docker-compose.yml`** : 5 services, networks, volumes
2. **Ouvrir `backend/Dockerfile`** : multi-stage, non-root, healthcheck
3. **Ouvrir `frontend/Dockerfile`** : 3 stages, output standalone
4. **Ouvrir `nginx/nginx.conf`** : routing + rate limit + WebSocket

Pour la **demo** (cluster Kubernetes), aller dans le dossier parent `k8s/`
et suivre `c:/cluster/README.md`.

---

## Tester localement (sans cluster)

```bash
# Pre-requis : Docker Desktop installe et lance

cd c:/LottoTi                           # le source code
cp .env.example .env                    # editer les valeurs

docker-compose up -d --build            # build + lancer la stack
docker-compose ps                       # verifier que tout est healthy

# Acces : http://localhost
# API direct : http://localhost/api/health

docker-compose logs -f                  # logs en streaming
docker-compose down                     # arreter (sans toucher aux volumes)
```

---

**Auteur** : Equipe LottoTi
**Date** : Mai 2026
**Cible** : Projet final ESGI - Clusterisation de container
