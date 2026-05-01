# Capture 08 — Rolling Update zero-downtime

## Objectif

**Critère bonus** : Bonus 4 (1 point) — *« Rolling Update / Canary : déploiement progressif »*

## Commande

```bash
# Lance un trafic continu
while true; do
  curl -sk -o /dev/null -w "%{http_code} " --resolve api.lottoti.local:30443:$MASTER_IP \
    https://api.lottoti.local:30443/api/health
  sleep 0.5
done > /tmp/curl-during-update.log &
TRAFFIC_PID=$!

# Trigger un rolling update
kubectl -n lottoti patch deploy/backend \
  -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"rollout.lottoti/restartedAt\":\"$(date +%s)\"}}}}}"

# Suivre le rollout
kubectl -n lottoti rollout status deploy/backend

# Verifier zero downtime
kill $TRAFFIC_PID
echo "Codes HTTP recus pendant le rollout :"
sort /tmp/curl-during-update.log | uniq -c
```

## Résultat attendu

**Pendant le rollout (`kubectl rollout status` output)** :
```
Waiting for deployment "backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "backend" rollout to finish: 1 of 2 updated replicas are available...
Waiting for deployment "backend" rollout to finish: 1 old replicas are pending termination...
deployment "backend" successfully rolled out
```

**Codes HTTP** :
```
    142 200    <-- aucune erreur
```

(Si quelques 502 apparaissent, c'est qu'il faut augmenter `terminationGracePeriodSeconds` ou ajuster le `preStop`.)

## Screenshot

- `output/08a-rolling-status.png` (le `kubectl rollout status` en cours)
- `output/08b-no-503.png` (compte des codes HTTP : 100% de 200)

## Validation

- [ ] `maxSurge: 1, maxUnavailable: 0` defini dans le manifest backend
- [ ] Le rollout se termine sans timeout
- [ ] **0 erreur HTTP** pendant le rollout (zero-downtime)
- [ ] Le `rollout history` montre la nouvelle revision :

```bash
kubectl -n lottoti rollout history deploy/backend
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         (rolling update annotation)
```
