# Capture 15 — Resource Requests/Limits + QoS

## Objectif

**Critère bonus** : Bonus 1 (1 point) — *« Resource Requests & Limits + QoS : afin de réguler la conso CPU/RAM »*

## Commande

```bash
# Vue d'ensemble : QoS class par pod
kubectl -n lottoti get pods -o custom-columns=\
NAME:.metadata.name,QOS:.status.qosClass,NODE:.spec.nodeName

# Detail des resources d'un backend
kubectl -n lottoti describe pod -l app=backend | grep -A 10 "Limits\|Requests"

# Vue resource du namespace
kubectl -n lottoti top pods --containers
kubectl -n lottoti top nodes

# Verifier que les limits sont effectives
kubectl -n lottoti exec deploy/backend -- cat /sys/fs/cgroup/memory.max
# Doit etre <= 768Mi en bytes (805306368)
```

## Résultat attendu

```
$ kubectl -n lottoti get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME                       QOS
backend-7d9b8c5f7-abc12    Burstable
backend-7d9b8c5f7-xyz34    Burstable
frontend-6b7c4d8e9-aaa     Burstable
frontend-6b7c4d8e9-bbb     Burstable
frontend-6b7c4d8e9-ccc     Burstable
postgres-0                 Burstable
redis-0                    Burstable

$ kubectl -n lottoti describe pod backend-7d9b8c5f7-abc12 | grep -A 5 "Limits\|Requests"
    Limits:
      cpu:     1
      memory:  768Mi
    Requests:
      cpu:     200m
      memory:  384Mi

$ kubectl -n lottoti top pods
NAME                       CPU(cores)   MEMORY(bytes)
backend-7d9b8c5f7-abc12    25m          156Mi
backend-7d9b8c5f7-xyz34    18m          142Mi
frontend-6b7c4d8e9-aaa     10m          85Mi
postgres-0                 30m          240Mi
redis-0                    5m           30Mi
```

## Screenshot

- `output/15a-pods-qos.png` (toutes les classes QoS Burstable)
- `output/15b-resources-describe.png` (limits + requests)
- `output/15c-top-pods.png` (consommation reelle vs limites)

## Validation

- [ ] Tous les pods ont QoS class **Burstable** (requests != limits)
- [ ] Backend : `requests: cpu=200m, memory=384Mi` / `limits: cpu=1, memory=768Mi`
- [ ] Frontend : `requests: cpu=100m, memory=192Mi` / `limits: cpu=500m, memory=384Mi`
- [ ] Postgres : `requests: cpu=200m, memory=512Mi` / `limits: cpu=1, memory=1Gi`
- [ ] Redis : `requests: cpu=50m, memory=64Mi` / `limits: cpu=250m, memory=192Mi`
- [ ] `kubectl top` confirme que la conso reelle est inferieure aux limits
- [ ] **Conclusion** : la consommation est encadree, pas de runaway pod possible
