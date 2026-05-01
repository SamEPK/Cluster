# Capture 03 — Persistance (PVC + PV)

## Objectif

**Critère barème** : Persistance (2 points) — *« BDD ou fichiers uploadés doivent survivre aux redéploiements »*

## Commande

```bash
kubectl -n lottoti get pvc
kubectl get pv
kubectl get sc
```

## Résultat attendu

```
NAME                          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS
pgdata-postgres-0             Bound    pvc-aaaaaaa  5Gi        RWO            longhorn
redisdata-redis-0             Bound    pvc-bbbbbbb  1Gi        RWO            longhorn
uploads                       Bound    pvc-ccccccc  5Gi        RWX            longhorn   <-- RWX !

NAME                                    CAPACITY   STATUS   CLAIM
pvc-aaaaaaa-...                         5Gi        Bound    lottoti/pgdata-postgres-0
pvc-bbbbbbb-...                         1Gi        Bound    lottoti/redisdata-redis-0
pvc-ccccccc-...                         5Gi        Bound    lottoti/uploads

NAME                 PROVISIONER          RECLAIMPOLICY   ALLOWVOLUMEEXPANSION   DEFAULT
longhorn (default)   driver.longhorn.io   Delete          true                   yes
local-path           rancher.io/local-path Delete         false                  no
```

## Screenshot

`![PVC et PV bound](output/03-pvc-pv.png)`

## Validation

- [ ] 3 PVC en STATUS Bound
- [ ] `uploads` en mode **ReadWriteMany (RWX)** — c'est ce qui permet le partage entre les 2 backends
- [ ] StorageClass `longhorn` est defaut

## Commentaire

C'est le cœur de l'exigence "fichiers uploadés survivent aux redéploiements".
La preuve concrète vient de la capture **07-kill-db-persistence.md** (kill du pod, donnée toujours là).
