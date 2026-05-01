# Capture 09 — Rollback automatique

## Objectif

**Critère bonus** : Bonus 7 (1 point) — *« Rollback automatique en cas d'échec »*

## Commande

```bash
# Voir l'historique
kubectl -n lottoti rollout history deploy/backend

# Simuler un deploiement casse: image inexistante
kubectl -n lottoti set image deploy/backend api=lottoti/backend:DOES_NOT_EXIST

# Suivre le rollout (va echouer)
kubectl -n lottoti rollout status deploy/backend --timeout=2m
# echec attendu

# Etat des pods (nouveaux pods ImagePullBackOff)
kubectl -n lottoti get pods -l app=backend

# Rollback manuel a la version precedente
kubectl -n lottoti rollout undo deploy/backend
kubectl -n lottoti rollout status deploy/backend
kubectl -n lottoti get pods -l app=backend

# Verifier que l'image est de retour a 1.0.0
kubectl -n lottoti describe deploy/backend | grep -E "Image:.*lottoti"
```

## Résultat attendu

**Avant rollback** :
```
NAME                       READY   STATUS             RESTARTS
backend-7d9b8c5f7-abc12    1/1     Running            0           <-- ancien
backend-7d9b8c5f7-xyz34    1/1     Running            0           <-- ancien
backend-broken-9999        0/1     ImagePullBackOff   0           <-- nouveau casse
```

**Après rollback** :
```
NAME                       READY   STATUS    RESTARTS
backend-7d9b8c5f7-abc12    1/1     Running   0
backend-7d9b8c5f7-xyz34    1/1     Running   0

Image: lottoti/backend:1.0.0    <-- restored
```

## Screenshot

- `output/09a-broken-deployment.png` (ImagePullBackOff visible)
- `output/09b-rollback-success.png` (apres undo)

## Validation

- [ ] Le manifest a `revisionHistoryLimit: 5` (permet le rollback sur 5 versions)
- [ ] `rollout undo` restaure l'image precedente automatiquement
- [ ] Aucune intervention manuelle de l'image
- [ ] **Bonus** : la pipeline CI/CD `.github/workflows/ci-cd.yml` execute `rollout undo` automatiquement si `rollout status` timeout (job `deploy`)
