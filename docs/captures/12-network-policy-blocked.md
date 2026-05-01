# Capture 12 — NetworkPolicy bloque le trafic non-autorisé

## Objectif

**Critère bonus** : Bonus 3 (1 point) — *« NetworkPolicy : restreindre la communication réseau »*

## Commande

```bash
# Lister les policies actives
kubectl -n lottoti get networkpolicy

# Test 1 : depuis frontend vers backend (autorise)
kubectl -n lottoti exec deploy/frontend -- nc -vz -w 3 backend 5000
# Connection succeeded

# Test 2 : depuis frontend vers postgres (BLOQUE)
kubectl -n lottoti exec deploy/frontend -- nc -vz -w 5 postgres 5432
# Timeout / Connection refused

# Test 3 : depuis frontend vers redis (BLOQUE)
kubectl -n lottoti exec deploy/frontend -- nc -vz -w 5 redis 6379
# Timeout / Connection refused

# Test 4 : depuis backend vers postgres (autorise)
kubectl -n lottoti exec deploy/backend -- nc -vz -w 3 postgres 5432
# Connection succeeded

# Test 5 : depuis un pod hors namespace (cree pour le test)
kubectl run -n default test-attack --image=alpine -i --tty --rm \
  --restart=Never -- sh -c "apk add -q netcat-openbsd && nc -vz -w 5 backend.lottoti.svc.cluster.local 5000"
# Timeout (le namespace 'default' n'a pas le label kubernetes.io/metadata.name=traefik)
```

## Résultat attendu

```
$ kubectl -n lottoti get networkpolicy
NAME                              POD-SELECTOR           AGE
default-deny-all                  <none>                 5m
allow-dns                         <none>                 5m
frontend-allow-from-ingress       app=frontend           5m
frontend-egress                   app=frontend           5m
backend-allow-ingress             app=backend            5m
backend-egress                    app=backend            5m
postgres-allow-backend            app=postgres           5m
redis-allow-backend               app=redis              5m

# Test 1 (autorise)
$ kubectl -n lottoti exec deploy/frontend -- nc -vz -w 3 backend 5000
backend (10.43.x.x:5000) open

# Test 2 (BLOQUE)
$ kubectl -n lottoti exec deploy/frontend -- nc -vz -w 5 postgres 5432
nc: postgres (10.43.x.y:5432): Operation timed out
command terminated with exit code 1   <-- BLOQUE PAR NETWORKPOLICY
```

## Screenshot

- `output/12a-policies-list.png` (les 8 policies actives)
- `output/12b-allowed-frontend-backend.png` (test 1 succeeds)
- `output/12c-blocked-frontend-postgres.png` (test 2 timeout)

## Validation

- [ ] 8 NetworkPolicies actives dans le namespace lottoti
- [ ] Frontend → Backend (5000) : OK
- [ ] Frontend → Postgres (5432) : BLOQUE
- [ ] Frontend → Redis (6379) : BLOQUE
- [ ] Backend → Postgres : OK
- [ ] Backend → Redis : OK
- [ ] Pod externe (namespace default) → backend : BLOQUE
- [ ] **Conclusion** : zero-trust applique strictement
