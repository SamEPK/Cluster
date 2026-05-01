# Capture 06 — Kill pod backend → recovery automatique

## Objectif

**Critère barème** : Persistance (2 points) + Déploiement HA (5 points) — *« Si je décide de delete un pod ou un CT, ça doit remonter automatiquement sans soucis »*

## Commande

```bash
# Etat avant
kubectl -n lottoti get pods -l app=backend -o wide

# Watch en parallele
kubectl -n lottoti get pods -l app=backend -w &
WATCH_PID=$!

# Kill brutal
TARGET=$(kubectl -n lottoti get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo "Killing $TARGET..."
kubectl -n lottoti delete pod "$TARGET" --grace-period=0 --force

# Attendre 30s pour observer le recovery
sleep 30
kill $WATCH_PID

# Etat final
kubectl -n lottoti get pods -l app=backend -o wide
```

## Résultat attendu

**Watch durant le kill** :
```
backend-7d9b8c5f7-abc12   1/1   Running        worker1
backend-7d9b8c5f7-xyz34   1/1   Running        worker2
backend-7d9b8c5f7-abc12   1/1   Terminating    worker1
backend-7d9b8c5f7-pdq99   0/1   Pending        <none>      <-- recree par ReplicaSet
backend-7d9b8c5f7-pdq99   0/1   ContainerCreating  worker1
backend-7d9b8c5f7-pdq99   0/1   Init:0/2       worker1
backend-7d9b8c5f7-pdq99   0/1   Init:1/2       worker1
backend-7d9b8c5f7-pdq99   1/1   Running        worker1
```

**Après** : 2 replicas Running, le AGE du nouveau est < 30s.

## Screenshot

`![Pod kill et recovery](output/06-kill-pod-recovery.png)`

## Validation

- [ ] Recovery en < 30 secondes (init containers + image deja en cache)
- [ ] Aucune intervention manuelle
- [ ] Le service backend reste accessible pendant le kill (l'autre replica encaisse) :

```bash
# Test continuite pendant le kill (a lancer dans un autre terminal)
while true; do
  curl -sk -o /dev/null -w "%{http_code} " --resolve api.lottoti.local:30443:$MASTER_IP \
    https://api.lottoti.local:30443/api/health
  sleep 0.5
done
# Attendu: une serie de 200, jamais de 502/503
```
