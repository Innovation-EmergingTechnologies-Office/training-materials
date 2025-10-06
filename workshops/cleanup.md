# Comandi di Cleanup - Workshop Kubernetes

Questi comandi permettono di pulire tutte le risorse create durante il workshop.

## Cleanup Use Case 1 - Image Pull Error
```bash
kubectl delete -f use-case-1-image-pull-error/broken-deployment.yaml
kubectl delete -f use-case-1-image-pull-error/fixed-deployment.yaml
```

## Cleanup Use Case 2 - CrashLoopBackOff
```bash
kubectl delete -f use-case-2-crashloop/broken-app.yaml
kubectl delete -f use-case-2-crashloop/fixed-app.yaml
```

## Cleanup Use Case 3 - Out of Memory
```bash
kubectl delete -f use-case-3-oom/memory-hungry-app.yaml
kubectl delete -f use-case-3-oom/fixed-memory-app.yaml
kubectl delete -f use-case-3-oom/monitoring.yaml
```

## Cleanup Completo
```bash
# Eliminare tutti i deployment
kubectl delete deployment --all

# Eliminare tutti i servizi (tranne kubernetes)
kubectl delete service --all --selector='!kubernetes.io/cluster-service'

# Eliminare tutte le ConfigMap
kubectl delete configmap --all

# Eliminare tutti i Secret (tranne quelli di sistema)
kubectl delete secret --all --field-selector='type!=kubernetes.io/service-account-token'

# Eliminare tutti i PVC
kubectl delete pvc --all

# Eliminare tutti i Job
kubectl delete job --all

# Eliminare ServiceAccount e RBAC
kubectl delete serviceaccount memory-monitor-sa
kubectl delete clusterrolebinding memory-monitor-binding
kubectl delete clusterrole memory-monitor-role
```

## Verifica Cleanup
```bash
kubectl get all
kubectl get configmap
kubectl get secret
kubectl get pvc
kubectl get events
```
