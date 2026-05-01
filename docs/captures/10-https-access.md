# Capture 10 — HTTPS depuis le navigateur

## Objectif

**Critère barème** : Sécurité (2 points) + Exposition (2 points) — *« HTTPS exposé via Ingress »*

## Pré-requis

```
# /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
<MASTER_IP>  lottoti.local  api.lottoti.local
```

Importer la CA self-signed dans le browser pour eviter le warning :

```bash
# Export du CA cert
kubectl -n cert-manager get secret lottoti-ca-key-pair -o jsonpath='{.data.tls\.crt}' \
  | base64 -d > lottoti-ca.crt

# Linux (Chrome/Firefox via NSS)
sudo cp lottoti-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Mac
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain lottoti-ca.crt

# Windows (Edge/Chrome)
certutil -addstore -f "ROOT" lottoti-ca.crt
```

## Commande / Action

1. Ouvrir https://lottoti.local:30443/ dans le navigateur
2. Verifier le **cadenas vert** dans la barre d'URL
3. Cliquer sur le cadenas → "Certificate" → verifier "Issued by: lottoti-ca"

```bash
# Alternative CLI :
curl -kvI --resolve lottoti.local:30443:$MASTER_IP https://lottoti.local:30443/ 2>&1 \
  | grep -E "subject|issuer|HTTP|Location"
```

## Résultat attendu

```
* Server certificate:
*  subject: CN=lottoti.local
*  start date: ...
*  expire date: ...
*  subjectAltName: host "lottoti.local" matched cert's "lottoti.local"
*  issuer: O=LottoTi; OU=LottoTi Cluster; CN=lottoti-ca
*  SSL certificate verify ok.

< HTTP/2 200
< content-type: text/html; charset=utf-8
< x-frame-options: DENY
< x-content-type-options: nosniff
```

## Screenshot

- `output/10a-https-padlock.png` (cadenas vert dans browser)
- `output/10b-cert-details.png` (detail certificat: issuer = lottoti-ca)
- `output/10c-app-loaded.png` (interface LottoTi qui s'affiche)

## Validation

- [ ] HTTPS fonctionne (cadenas vert si CA importee, sinon warning attendu)
- [ ] Certificat emis par `lottoti-ca`
- [ ] Headers de securite presents (X-Frame-Options, X-Content-Type-Options)
- [ ] Page Next.js LottoTi s'affiche correctement
- [ ] http://lottoti.local:30080/ → redirige vers https (301)
