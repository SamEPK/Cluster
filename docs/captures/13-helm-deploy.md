# Capture 13 — Déploiement via Helm Chart

## Objectif

**Critère bonus** : Bonus 8 (1 point) — *« Helm Charts : paramétrer un chart pour déployer la stack »*

## Commande

```bash
# Lint du chart
helm lint charts/lottoti

# Render (verifier les manifests generes)
helm template lottoti charts/lottoti \
  --namespace lottoti \
  --set secrets.createSecret=true \
  --set secrets.postgresPassword=$(openssl rand -hex 24) \
  --set secrets.flaskSecretKey=$(openssl rand -hex 32) \
  --set secrets.jwtSecretKey=$(openssl rand -hex 32) \
  | head -50

# Install (sur cluster vide)
kubectl create namespace lottoti-helm
helm install lottoti charts/lottoti \
  --namespace lottoti-helm \
  --set secrets.createSecret=true \
  --set secrets.postgresPassword=$(openssl rand -hex 24) \
  --set secrets.flaskSecretKey=$(openssl rand -hex 32) \
  --set secrets.jwtSecretKey=$(openssl rand -hex 32) \
  --wait --timeout 5m

# Verifier
helm list -n lottoti-helm
kubectl -n lottoti-helm get all

# Upgrade : changer une valeur
helm upgrade lottoti charts/lottoti \
  --namespace lottoti-helm \
  --reuse-values \
  --set frontend.replicas=5

kubectl -n lottoti-helm get deploy frontend

# Rollback Helm
helm rollback lottoti 1 -n lottoti-helm

# Cleanup
helm uninstall lottoti -n lottoti-helm
kubectl delete namespace lottoti-helm
```

## Résultat attendu

```
$ helm lint charts/lottoti
==> Linting charts/lottoti
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

$ helm install lottoti charts/lottoti -n lottoti-helm ...
NAME: lottoti
LAST DEPLOYED: ...
NAMESPACE: lottoti-helm
STATUS: deployed
REVISION: 1

$ helm list -n lottoti-helm
NAME    NAMESPACE     REVISION  UPDATED   STATUS    CHART          APP VERSION
lottoti lottoti-helm  1         ...       deployed  lottoti-1.0.0  1.0.0

$ kubectl -n lottoti-helm get all
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-xxx                 1/1     Running   0          2m
pod/backend-yyy                 1/1     Running   0          2m
pod/frontend-aaa                1/1     Running   0          2m
pod/frontend-bbb                1/1     Running   0          2m
pod/frontend-ccc                1/1     Running   0          2m
pod/postgres-0                  1/1     Running   0          2m
pod/redis-0                     1/1     Running   0          2m

# Apres upgrade frontend.replicas=5
$ kubectl -n lottoti-helm get deploy frontend
NAME       READY   UP-TO-DATE   AVAILABLE
frontend   5/5     5            5

# Rollback
$ helm rollback lottoti 1 -n lottoti-helm
Rollback was a success! Happy Helming!
```

## Screenshot

- `output/13a-helm-lint.png`
- `output/13b-helm-install.png`
- `output/13c-helm-upgrade-rollback.png`

## Validation

- [ ] `helm lint` passe sans erreur
- [ ] `helm install` deploie les 5 services (frontend, backend, postgres, redis, ingress)
- [ ] `helm upgrade` permet de changer le nombre de replicas a la volee
- [ ] `helm rollback` revient a la revision precedente
- [ ] Le chart est entierement parametrable via `values.yaml`
