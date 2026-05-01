# Capture 07 — Kill DB pod, données préservées (PV survie)

## Objectif

**Critère barème** : Persistance (2 points) — *« BDD ou fichiers uploadés doivent survivre aux redéploiements »*

## Commande

```bash
# 1. Inserer une donnee de test
kubectl -n lottoti exec postgres-0 -- psql -U lottoit -d lottoit -c \
  "CREATE TABLE IF NOT EXISTS persistence_test (id serial, marker text);"
kubectl -n lottoti exec postgres-0 -- psql -U lottoit -d lottoit -c \
  "INSERT INTO persistence_test (marker) VALUES ('survived $(date +%s)');"
kubectl -n lottoti exec postgres-0 -- psql -U lottoit -d lottoit -c \
  "SELECT * FROM persistence_test;"

# 2. Etat PVC avant
kubectl -n lottoti get pvc pgdata-postgres-0

# 3. Kill brutal
kubectl -n lottoti delete pod postgres-0 --grace-period=0 --force

# 4. Attente recreation
kubectl -n lottoti rollout status statefulset/postgres --timeout=2m

# 5. Verifier que la donnee est toujours la
kubectl -n lottoti exec postgres-0 -- psql -U lottoit -d lottoit -c \
  "SELECT * FROM persistence_test;"

# 6. PVC inchange ?
kubectl -n lottoti get pvc pgdata-postgres-0
```

## Résultat attendu

**Avant kill** :
```
 id |       marker
----+---------------------
  1 | survived 1719567890
(1 row)

NAME                STATUS   VOLUME       CAPACITY   ACCESS MODES   AGE
pgdata-postgres-0   Bound    pvc-aaaaaaa  5Gi        RWO            10m
```

**Après recreation pod** (postgres-0 recreated, le PVC suit le StatefulSet) :
```
 id |       marker
----+---------------------
  1 | survived 1719567890     <-- DONNEE TOUJOURS LA
(1 row)

NAME                STATUS   VOLUME       CAPACITY   ACCESS MODES   AGE
pgdata-postgres-0   Bound    pvc-aaaaaaa  5Gi        RWO            10m  <-- meme PV
```

## Screenshot

3 captures :
- `output/07a-insert-data.png` (la donnée existe avant le kill)
- `output/07b-pod-killed.png` (postgres-0 deleted, recreated, AGE < 30s)
- `output/07c-data-survived.png` (la donnée est toujours là)

## Validation

- [ ] Le pod postgres-0 a un AGE < 1min (a ete recree)
- [ ] La table `persistence_test` contient toujours la ligne inseree avant le kill
- [ ] Le PVC `pgdata-postgres-0` est le **meme** (meme VOLUME UID)
- [ ] **Conclusion** : la persistance fonctionne, le redeploiement de pod n'efface pas les donnees
