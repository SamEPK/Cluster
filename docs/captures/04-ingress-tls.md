# Capture 04 — Ingress + Certificate TLS

## Objectif

**Critère barème** : Exposition (2 points) — *« Load Balancer/Ingress »* + Sécurité (2 points) — *« HTTPS »*

## Commande

```bash
kubectl -n lottoti get ingress,certificate
kubectl get clusterissuer
kubectl -n lottoti describe certificate lottoti-tls | head -30
kubectl -n traefik get svc traefik
```

## Résultat attendu

```
NAME                                  CLASS    HOSTS                              ADDRESS        PORTS     AGE
ingress.networking.k8s.io/lottoti     traefik  lottoti.local,api.lottoti.local    10.43.x.y     80,443    5m
ingress.networking.k8s.io/lottoti-redirect traefik lottoti.local,api...           10.43.x.y     80        5m

NAME                                  READY   SECRET         AGE
certificate.cert-manager.io/lottoti-tls   True   lottoti-tls    5m

NAME                                  READY   AGE
clusterissuer.cert-manager.io/selfsigned-bootstrap   True   10m
clusterissuer.cert-manager.io/lottoti-ca-issuer      True   10m

Status:
  Conditions:
    Last Transition Time:  ...
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2026-07-26T13:42:11Z
  Renewal Time:            2026-06-26T13:42:11Z

NAME      TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)
traefik   NodePort   10.43.x.x     <none>        80:30080/TCP, 443:30443/TCP
```

## Screenshot

`![Ingress et certificate Ready](output/04-ingress-tls.png)`

## Validation

- [ ] Ingress `lottoti` exposé avec hosts lottoti.local + api.lottoti.local
- [ ] Certificate `lottoti-tls` en READY=True
- [ ] ClusterIssuer `lottoti-ca-issuer` en READY=True
- [ ] Service Traefik en NodePort 30080/30443
