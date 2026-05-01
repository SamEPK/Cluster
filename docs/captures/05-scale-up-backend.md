# Capture 05 — Scale up backend (2 → 5 → 2)

## Objectif

**Critère barème** : Déploiement (5 points) — *« Tester la haute dispo (scale, kill pod/container) »*

## Commande

```bash
# Avant
kubectl -n lottoti get pods -l app=backend -o wide

# Scale up
kubectl -n lottoti scale deploy/backend --replicas=5
kubectl -n lottoti get pods -l app=backend -w &
sleep 30
kill %1

# Apres
kubectl -n lottoti get pods -l app=backend -o wide

# Retour normal
kubectl -n lottoti scale deploy/backend --replicas=2
```

## Résultat attendu

**Avant** :
```
NAME                       READY   STATUS    NODE
backend-7d9b8c5f7-abc12    1/1     Running   worker1
backend-7d9b8c5f7-xyz34    1/1     Running   worker2
```

**Pendant le scale-up (watch)** :
```
backend-7d9b8c5f7-newaa    0/1     Pending   <none>
backend-7d9b8c5f7-newbb    0/1     ContainerCreating  worker1
backend-7d9b8c5f7-newcc    0/1     ContainerCreating  worker2
backend-7d9b8c5f7-newaa    0/1     Init:0/2  worker1
backend-7d9b8c5f7-newbb    0/1     Init:1/2  worker1
backend-7d9b8c5f7-newcc    0/1     PodInitializing worker2
backend-7d9b8c5f7-newaa    1/1     Running   worker1
...
```

**Après** :
```
NAME                       READY   STATUS    NODE
backend-7d9b8c5f7-abc12    1/1     Running   worker1
backend-7d9b8c5f7-xyz34    1/1     Running   worker2
backend-7d9b8c5f7-newaa    1/1     Running   worker1
backend-7d9b8c5f7-newbb    1/1     Running   worker2
backend-7d9b8c5f7-newcc    1/1     Running   worker1
```

## Screenshot

3 captures ideales :
- Avant : `output/05a-scale-before.png`
- Watch : `output/05b-scale-watch.png`
- Apres : `output/05c-scale-after.png`

## Validation

- [ ] Le scale up demarre en quelques secondes
- [ ] Les nouveaux pods sont repartis sur worker1 et worker2 (PodAntiAffinity)
- [ ] Le scale down restaure 2 pods sans erreur
