# Capture 11 — HPA Autoscaling sous charge

## Objectif

**Critère bonus** : Bonus 5 (1 point) — *« Autoscaling horizontal (k3s HPA) »*

## Commande

```bash
# Etat HPA initial
kubectl -n lottoti get hpa
# backend Deployment/backend cpu: 5%/70%, memory: 30%/80% min:2 max:8 REPLICAS: 2

# Generer du trafic pour faire monter le CPU
kubectl run -n lottoti -i --tty --rm load-test --restart=Never \
  --image=ghcr.io/six-ddc/plow:v1.4.0 \
  -- -c 100 -d 90s http://backend:5000/api/health

# Dans un autre terminal, watcher HPA
kubectl -n lottoti get hpa -w
```

## Résultat attendu

**Watch HPA** (durant les 90s de load) :
```
NAME       REFERENCE             TARGETS              MINPODS  MAXPODS  REPLICAS
backend    Deployment/backend    cpu: 5%/70%          2        8        2
backend    Deployment/backend    cpu: 75%/70%         2        8        2     <-- depasse seuil
backend    Deployment/backend    cpu: 80%/70%         2        8        4     <-- HPA scale
backend    Deployment/backend    cpu: 65%/70%         2        8        4
backend    Deployment/backend    cpu: 90%/70%         2        8        6     <-- continue
backend    Deployment/backend    cpu: 60%/70%         2        8        6
... (load termine)
backend    Deployment/backend    cpu: 5%/70%          2        8        6
backend    Deployment/backend    cpu: 5%/70%          2        8        2     <-- scale down apres 5min
```

```bash
# Etat pods
kubectl -n lottoti get pods -l app=backend
# Doit montrer 4-8 pods actifs pendant la charge

# events
kubectl -n lottoti describe hpa backend | tail -15
# Events:
#   Type    Reason             Age   From                       Message
#   ----    ------             ----  ----                       -------
#   Normal  SuccessfulRescale  1m    horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
#   Normal  SuccessfulRescale  2m    horizontal-pod-autoscaler  New size: 6; reason: cpu resource utilization (percentage of request) above target
```

## Screenshot

- `output/11a-hpa-before.png` (CPU 5%, replicas 2)
- `output/11b-hpa-scaling.png` (CPU 80%, replicas 4-6)
- `output/11c-hpa-events.png` (events SuccessfulRescale)

## Validation

- [ ] HPA defini avec `minReplicas=2, maxReplicas=8`
- [ ] Le CPU monte au-dessus de 70%
- [ ] Replicas augmente (max observe : 4-8 selon la charge)
- [ ] Events `SuccessfulRescale` visibles
- [ ] Apres la fin du load, scale down vers minReplicas (5 min de stabilization)
