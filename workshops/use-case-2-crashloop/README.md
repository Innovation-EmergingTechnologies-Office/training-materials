# Use Case 2: CrashLoopBackOff

## Problem Description
This scenario simulates an application that goes into a crash loop due to incorrect configuration. The container starts but terminates immediately due to:
- Missing or incorrect configuration
- Unavailable dependencies
- Required environment variables not set
- Configuration files with incorrect syntax

## Simulated Scenario
A Node.js application requires a `DATABASE_URL` environment variable to connect to the PostgreSQL database. Without this configuration, the application terminates immediately causing a CrashLoopBackOff.

## Problematic Deployment File
See `broken-app.yaml` - deployment without the necessary configuration.

## Diagnostic Commands

### 1. Apply the resources and observe the behavior
```bash
kubectl apply -f broken-app.yaml
```

### 2. Check the pod status
```bash
kubectl get pods -l app=nodejs-app
```

### 3. View details of the crashing pod
```bash
kubectl describe pod <pod-name>
```

### 4. Analyze the container logs
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # logs from the previous instance
```

### 5. Check recent events
```bash
kubectl get events --field-selector reason=BackOff
```

## Expected Error
The pod will show `CrashLoopBackOff` status with increasing restart count and in the logs we will see:
```
Error: DATABASE_URL environment variable is required
    at Object.<anonymous> (/app/server.js:5:11)
```

## Complete Solution
The solution includes:
1. **ConfigMap** with the application configuration
2. **Secret** for PostgreSQL database credentials
3. **PersistentVolumeClaim** for data persistence
4. **PostgreSQL Deployment** with health checks
5. **Service** to expose the database internally
6. **Node.js Deployment** updated to use the configuration

## Resolution Commands
```bash
# Apply the complete fix (includes PostgreSQL)
kubectl apply -f fixed-app.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres-db --timeout=60s

# Verify that both pods are running
kubectl get pods -l app=nodejs-app
kubectl get pods -l app=postgres-db

# Check the application logs
kubectl logs -l app=nodejs-app

# Verify database connectivity
kubectl exec -it deployment/nodejs-app -- wget -qO- http://localhost:3000

# Test the application from outside
kubectl port-forward deployment/nodejs-app 3000:3000
```

## Configuration Verification
```bash
# Check the created resources
kubectl get configmap nodejs-app-config
kubectl get secret postgres-secret
kubectl get pvc postgres-pvc
kubectl get svc db-service

# Test the database connection
kubectl exec -it deployment/postgres-db -- psql -U user -d myapp -c "\l"
```
