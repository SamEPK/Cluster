# Guide de revision LottoTi - Clusterisation de container (ESGI)

> ZIP partage entre potes pour reviser le projet final.
> Tout ce qu'il faut pour comprendre ET refaire l'exercice est dans ce dossier.

---

## Par ou commencer ?

### 1. Comprendre le contexte (5 min)
Lire dans cet ordre :
1. **`SUJET DU PROJET (2).pdf`** - le sujet ESGI original (5 pages)
2. **`README.md`** - vue d'ensemble du projet, comment l'installer
3. **`ARCHITECTURE.md`** - schemas de l'architecture cluster

### 2. Comprendre l'etape Docker (10 min)
**`containerisation/`** = la stack Docker AVANT Kubernetes
- `containerisation/README.md` - explication des concepts (multi-stage, volumes, networks)
- `containerisation/docker-compose.yml` - 5 services orchestres
- `containerisation/backend/Dockerfile` - multi-stage Python
- `containerisation/frontend/Dockerfile` - multi-stage Next.js
- `containerisation/nginx/nginx.conf` - reverse proxy + rate limiting

### 3. Comprendre Kubernetes (30 min)
**`k8s/base/`** = 36 manifests YAML, organises par tier
TOUS COMMENTES LIGNE PAR LIGNE en francais. Ouvrir dans cet ordre :
1. `00-namespaces/` - notion de namespace
2. `15-cert-manager/` - chaine TLS (selfsigned -> CA -> Issuer)
3. `20-database/` - StatefulSet + PVC + ConfigMap
4. `25-redis/` - meme principe
5. `30-backend/` - Deployment + Service + HPA + PDB + initContainers
6. `40-frontend/` - Deployment 3 replicas
7. `50-ingress/` - Traefik + Middlewares + Certificate TLS
8. `60-policies/` - 8 NetworkPolicies zero-trust

### 4. Voir les preuves
**`docs/captures/output/`** = 16 captures PNG d'execution reelle
Ouvrir le `PROOF_REPORT.md` pour la liste commentee.

### 5. Voir la presentation
- **`docs/Presentation_LottoTi_Short.pptx`** - 15 slides (pour soutenance)
- **`docs/Presentation_LottoTi_Cluster.pptx`** - 45 slides (version detaillee)

---

## Vocabulaire de base (cheat sheet)

| Terme | Resume en 1 phrase |
|---|---|
| **Pod** | Unite de base : 1+ containers qui partagent reseau et volumes |
| **Deployment** | Garde toujours N pods identiques en vie (stateless) |
| **StatefulSet** | Comme Deployment mais avec identite stable + PVC dedie (BDD) |
| **Service** | Adresse IP/DNS stable qui load-balance vers les pods |
| **Ingress** | Porte d'entree HTTP(S) qui route selon URL vers les Services |
| **PVC** | Demande de disque persistant (survit aux pods) |
| **Secret** | Donnees sensibles (passwords) chiffrees dans etcd |
| **ConfigMap** | Variables non-sensibles (env, log level) |
| **NetworkPolicy** | Firewall L3/L4 entre pods |
| **HPA** | Autoscaling automatique selon CPU/memory |
| **PDB** | Garantie minAvailable pendant les drains de node |
| **Namespace** | Cloisonnement logique des ressources |

---

## Commandes kubectl essentielles

```bash
# Voir l'etat
kubectl get nodes -o wide                       # nodes du cluster
kubectl -n lottoti get all                      # tout dans le namespace
kubectl -n lottoti get pods -o wide             # pods avec IPs et nodes
kubectl -n lottoti get pvc                      # volumes persistants
kubectl -n lottoti get ingress,certificate,hpa  # ingress + certs + autoscaling

# Logs et debug
kubectl -n lottoti logs deploy/backend          # logs d'un Deployment
kubectl -n lottoti logs -f -l app=backend       # logs en streaming, par label
kubectl -n lottoti describe pod <pod-name>      # details + events
kubectl -n lottoti exec -it <pod-name> -- bash  # shell dans le pod

# Operations courantes
kubectl -n lottoti scale deploy/frontend --replicas=5    # scale manuel
kubectl -n lottoti rollout restart deploy/backend        # restart proprement
kubectl -n lottoti rollout undo deploy/frontend          # rollback
kubectl -n lottoti delete pod <pod-name>                 # tester le recovery

# Apply/delete
kubectl apply -k k8s/overlays/prod/             # deploie tout (Kustomize)
kubectl delete -k k8s/overlays/prod/            # supprime tout
```

---

## Structure du ZIP (referentiel rapide)

```
cluster/
|-- SUJET DU PROJET (2).pdf            <-- le sujet ESGI
|-- README.md                          <-- vue d'ensemble + tuto
|-- ARCHITECTURE.md                    <-- schemas archi
|-- REVISION_GUIDE.md                  <-- CE FICHIER
|
|-- containerisation/                  <-- ETAPE 1 : Docker
|   |-- README.md                      <-- explication + mapping vers k8s
|   |-- docker-compose.yml
|   |-- .env.example
|   |-- backend/  (Dockerfile + entrypoint + gunicorn.conf)
|   |-- frontend/ (Dockerfile)
|   `-- nginx/    (nginx.conf)
|
|-- k8s/                               <-- ETAPE 2 : Kubernetes
|   |-- base/                          <-- 36 manifests TOUS COMMENTES
|   |   |-- 00-namespaces/
|   |   |-- 15-cert-manager/           (3 fichiers TLS)
|   |   |-- 20-database/               (Postgres : SS + Service + ConfigMap)
|   |   |-- 25-redis/                  (Redis : SS + Service)
|   |   |-- 30-backend/                (Flask : Deploy + HPA + PDB + PVC)
|   |   |-- 40-frontend/               (Next.js : Deploy + HPA + PDB)
|   |   |-- 50-ingress/                (Traefik + Cert + Middlewares)
|   |   `-- 60-policies/               (8 NetworkPolicies)
|   `-- overlays/
|       |-- dev/                       (1 replica, debug)
|       |-- prod/                      (Multipass + Longhorn)
|       |-- k3d/                       (k3d + nginx stub)
|       `-- k3d-real/                  (k3d + vraies images)
|
|-- charts/                            <-- BONUS : Helm chart
|   `-- lottoti/
|
|-- scripts/                           <-- 8 scripts d'install
|   |-- 00-vars.sh                     (variables partagees)
|   |-- 01-create-vms.sh               (Multipass)
|   |-- 02-install-k3s.sh              (k3s server + agents)
|   |-- 03-install-storage.sh          (Longhorn)
|   |-- 04-install-cert-manager.sh     (cert-manager + CA)
|   |-- 05-install-ingress.sh          (Traefik)
|   |-- 06-build-images.sh             (Docker build + import)
|   |-- 07-deploy.sh                   (kubectl apply -k)
|   |-- 08-test-ha.sh                  (tests HA)
|   |-- 99-teardown.sh                 (cleanup)
|   |-- install-all.sh                 (one-shot all-in-one)
|   |-- generate-pptx.ps1              (genere PPTX 45 slides)
|   |-- generate-pptx-short.ps1        (genere PPTX 15 slides)
|   `-- render-captures.ps1            (txt -> PNG style terminal)
|
|-- docs/
|   |-- Presentation_LottoTi_Short.pptx     <-- 15 slides (soutenance)
|   |-- Presentation_LottoTi_Cluster.pptx   <-- 45 slides (longue)
|   |-- assets/                             (logo)
|   `-- captures/
|       |-- PROOF_REPORT.md             <-- rapport detaille des preuves
|       `-- output/                     <-- 16 PNG + 14 .txt (preuves live)
|
|-- launch-lottoti.ps1                 <-- ouvre Chrome direct sur l'app
|-- setup-hosts.ps1                    <-- ajoute lottoti.local au hosts (UAC)
`-- fix-kubeconfig.ps1                 <-- patch kubeconfig si port API change
```

---

## Pour reproduire le cluster (15 min sur ta machine)

### Pre-requis
```powershell
winget install Canonical.Multipass
winget install Docker.DockerDesktop
winget install Kubernetes.kubectl
winget install Helm.Helm
```

### Build complet
```bash
# A cote du repo cluster/, mettre le code source de l'app dans ../LottoTi/
cd cluster/scripts
chmod +x *.sh
./install-all.sh                      # ~15 minutes total
```

### Acces a l'app
```powershell
powershell C:\path\to\cluster\setup-hosts.ps1     # ajoute lottoti.local au hosts
# Puis ouvrir n'importe quel navigateur : https://lottoti.local:30443/
```

### Tests HA
```bash
./08-test-ha.sh                       # genere les .txt dans docs/captures/output/
powershell ../scripts/render-captures.ps1   # convertit txt -> PNG
```

### Cleanup
```bash
./99-teardown.sh                      # detruit les VMs + cleanup kubeconfig
```

---

## Questions probables a la soutenance

| Question | Reponse rapide |
|---|---|
| Pourquoi k3s plutot que k8s ? | Plus leger (~50 MB), parfait pour un cluster de 3 noeuds, meme API |
| Pourquoi Deployment vs StatefulSet ? | Deployment = stateless (frontend, backend), StatefulSet = stateful avec identite stable (BDD, Redis) |
| Pourquoi 2 backend et 3 frontend ? | Exigence du PDF section 3.2.4 (min 2 backend, min 3 frontend) |
| Comment la donnee survit au kill ? | Le PVC est decouple du Pod. Le StatefulSet recree le pod et remonte le MEME PVC |
| Comment HTTPS fonctionne ? | cert-manager genere automatiquement un cert via notre CA local (lottoti-ca), Traefik le sert sur :443 |
| C'est quoi la NetworkPolicy zero-trust ? | Default deny + allow explicite. Si un pod est compromis, il atteint UNIQUEMENT ce qui est autorise |
| Pourquoi Helm en bonus ? | Permet de parametrer le deploiement (replicas, storage, secrets) via values.yaml |
| Et le rolling update ? | maxUnavailable=0 garantit qu'on garde toujours N pods sains pendant la maj |

---

Bonne revision ! Pour les questions, ouvrir un YAML : tout est commente.
