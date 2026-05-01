# Capture 02 — Application déployée (namespaces + pods + replicas)

## Objectif

**Critère barème** : Déploiement (5 points) — *« front-end, back-end, BDD conteneurisés », « backend ≥ 2 replicas, frontend ≥ 3 replicas »*

## Commande

```bash
kubectl get namespaces | grep -E "lottoti|traefik|cert-manager|longhorn"
kubectl -n lottoti get all -o wide
kubectl -n lottoti get pods -l app=backend
kubectl -n lottoti get pods -l app=frontend
```

## Résultat attendu

```
NAME                STATUS   AGE
lottoti             Active   5m
traefik             Active   8m
cert-manager        Active   9m
longhorn-system     Active   12m

NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-7d9b8c5f7-abc12     1/1     Running   0          3m   <-- replica 1
pod/backend-7d9b8c5f7-xyz34     1/1     Running   0          3m   <-- replica 2
pod/frontend-6b7c4d8e9-a1b2c    1/1     Running   0          3m   <-- replica 1
pod/frontend-6b7c4d8e9-d3e4f    1/1     Running   0          3m   <-- replica 2
pod/frontend-6b7c4d8e9-g5h6i    1/1     Running   0          3m   <-- replica 3
pod/postgres-0                  1/1     Running   0          4m
pod/redis-0                     1/1     Running   0          4m

NAME                READY   UP-TO-DATE   AVAILABLE
deployment/backend  2/2     2            2
deployment/frontend 3/3     3            3
```

## Screenshot

`![Namespaces et pods](output/02-namespaces-pods.png)`

## Validation

- [ ] Namespace `lottoti` Active avec 4 namespaces support
- [ ] **2 pods backend** Running (replicas conforme au sujet)
- [ ] **3 pods frontend** Running (replicas conforme au sujet)
- [ ] 1 pod postgres-0 Running
- [ ] 1 pod redis-0 Running
- [ ] Tous READY 1/1, RESTARTS 0
