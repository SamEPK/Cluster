# Capture 14 — Secrets et ConfigMaps

## Objectif

**Critère barème** : Sécurité (2 points) — *« Secrets pour mots de passe et clés sensibles ; ConfigMaps pour variables moins sensibles »*

## Commande

```bash
# Lister les secrets
kubectl -n lottoti get secrets

# Voir le Secret applicatif (sans afficher les valeurs)
kubectl -n lottoti describe secret lottoti-secrets

# Verifier que les valeurs ne fuitent PAS dans les manifests bruts
kubectl -n lottoti get pod -l app=backend -o yaml \
  | grep -A 2 "POSTGRES_PASSWORD\|FLASK_SECRET_KEY"
# Doit montrer secretKeyRef, JAMAIS la valeur en clair

# Lister les ConfigMaps
kubectl -n lottoti get configmaps

# Voir le contenu du ConfigMap (non-sensible)
kubectl -n lottoti describe configmap backend-config
kubectl -n lottoti describe configmap postgres-config

# Verifier que le secret TLS est bien en place
kubectl -n lottoti get secret lottoti-tls -o yaml | head -10
```

## Résultat attendu

```
$ kubectl -n lottoti get secrets
NAME                  TYPE                                  DATA   AGE
lottoti-secrets       Opaque                                5      10m   <-- secrets app
lottoti-tls           kubernetes.io/tls                     2      10m   <-- TLS cert
default-token-xxxxx   kubernetes.io/service-account-token   3      10m

$ kubectl -n lottoti describe secret lottoti-secrets
Name:         lottoti-secrets
Namespace:    lottoti
Type:         Opaque

Data
====
FLASK_SECRET_KEY:        64 bytes
JWT_SECRET_KEY:          64 bytes
POSTGRES_PASSWORD:       48 bytes
STRIPE_SECRET_KEY:       42 bytes
STRIPE_WEBHOOK_SECRET:   38 bytes
                                  <-- valeurs jamais affichees, juste les tailles

$ kubectl -n lottoti describe configmap backend-config
Data
====
FLASK_ENV:        production
PORT:             5000
LOG_LEVEL:        info
FRONTEND_URL:     https://lottoti.local
CORS_ORIGINS:     https://lottoti.local
SEED_DB:          false
                                  <-- variables non-sensibles, ok en clair
```

## Screenshot

- `output/14a-secrets-list.png`
- `output/14b-secret-describe.png` (montre les noms des cles, pas les valeurs)
- `output/14c-configmap-describe.png` (variables en clair)

## Validation

- [ ] Secret `lottoti-secrets` contient les 5 cles sensibles (POSTGRES_PASSWORD, FLASK_SECRET_KEY, JWT_SECRET_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET)
- [ ] Secret `lottoti-tls` (kubernetes.io/tls) contient le certificat HTTPS
- [ ] `describe` ne montre que les TAILLES des secrets, jamais les valeurs
- [ ] ConfigMap `backend-config` et `postgres-config` contiennent les variables non-sensibles
- [ ] Les pods utilisent `secretKeyRef` et non des hardcoded values
