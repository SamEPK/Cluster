# Index des captures à fournir au rendu

Ce dossier contient **un fichier markdown par capture** à fournir dans le rapport final.
Chaque fichier suit le format :

```
1. Objectif (critère du barème adressé)
2. Commande exacte à lancer
3. Résultat attendu (texte)
4. Zone screenshot ← coller la capture .png/.jpg ici
5. Validation
```

---

## Liste des captures

| # | Fichier                                       | Critère barème  | Type     |
|---|-----------------------------------------------|-----------------|----------|
| 01 | [01-cluster-healthy.md](01-cluster-healthy.md) | Cluster (2pts) | terminal |
| 02 | [02-namespaces-pods.md](02-namespaces-pods.md) | Déploiement (5pts) | terminal |
| 03 | [03-pvc-pv.md](03-pvc-pv.md)                 | Persistance (2pts) | terminal |
| 04 | [04-ingress-tls.md](04-ingress-tls.md)        | Exposition (2pts) | terminal |
| 05 | [05-scale-up-backend.md](05-scale-up-backend.md) | Déploiement (5pts) | terminal |
| 06 | [06-kill-pod-recovery.md](06-kill-pod-recovery.md) | Persistance (2pts) | terminal |
| 07 | [07-kill-db-persistence.md](07-kill-db-persistence.md) | Persistance (2pts) | terminal |
| 08 | [08-rolling-update.md](08-rolling-update.md) | Bonus 4 (1pt) | terminal |
| 09 | [09-rollback.md](09-rollback.md) | Bonus 4 (1pt) | terminal |
| 10 | [10-https-access.md](10-https-access.md) | Sécurité (2pts) | navigateur |
| 11 | [11-hpa-load.md](11-hpa-load.md) | Bonus 5 (1pt) | terminal |
| 12 | [12-network-policy-blocked.md](12-network-policy-blocked.md) | Bonus 3 (1pt) | terminal |
| 13 | [13-helm-deploy.md](13-helm-deploy.md) | Bonus 8 (1pt) | terminal |
| 14 | [14-secrets-configmap.md](14-secrets-configmap.md) | Sécurité (2pts) | terminal |
| 15 | [15-resource-limits-qos.md](15-resource-limits-qos.md) | Bonus 1 (1pt) | terminal |

---

## Workflow recommandé

1. **Avant la démo** : lance `./scripts/install-all.sh` (~15 min)
2. **Pour chaque capture** :
   - Ouvre le `.md` correspondant
   - Lance la commande dans le terminal
   - Fais un screenshot avec **Win+Shift+S** (Windows) ou **Cmd+Shift+4** (Mac)
   - Sauve sous `docs/captures/output/<numero>-<nom>.png`
   - Colle dans le markdown : `![](output/01-cluster-healthy.png)`
3. **Au rendu** : zip le repo entier (avec `output/`) ou push sur Git

---

## Captures auto-générées (texte uniquement)

`./scripts/08-test-ha.sh` génère automatiquement les sorties texte des tests HA dans `docs/captures/output/*.txt`.
Tu peux soit les inclure tels quels, soit faire des screenshots de leur contenu pour la touche visuelle.
