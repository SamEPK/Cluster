# Capture 01 — Cluster healthy (1 master + 2 workers)

## Objectif

**Critère barème** : Cluster (2 points) — *« 1 master (manager) + 2 workers »*

## Commande

```bash
export KUBECONFIG=$HOME/.kube/config-lottoti
kubectl get nodes -o wide
kubectl get componentstatuses 2>/dev/null || echo "k3s n'expose pas les componentstatuses"
multipass list
```

## Résultat attendu

```
NAME      STATUS   ROLES                  AGE   VERSION         INTERNAL-IP    OS-IMAGE
master    Ready    control-plane,master   10m   v1.30.6+k3s1    10.211.55.10   Ubuntu 22.04
worker1   Ready    <none>                 9m    v1.30.6+k3s1    10.211.55.11   Ubuntu 22.04
worker2   Ready    <none>                 9m    v1.30.6+k3s1    10.211.55.12   Ubuntu 22.04

Name                    State             IPv4             Image
master                  Running           10.211.55.10     Ubuntu 22.04 LTS
worker1                 Running           10.211.55.11     Ubuntu 22.04 LTS
worker2                 Running           10.211.55.12     Ubuntu 22.04 LTS
```

## Screenshot

`![Cluster Ready 3 nodes](output/01-cluster-healthy.png)`

## Validation

- [ ] master en STATUS Ready, role `control-plane,master`
- [ ] worker1 et worker2 en STATUS Ready
- [ ] Multipass list montre les 3 VMs Running
