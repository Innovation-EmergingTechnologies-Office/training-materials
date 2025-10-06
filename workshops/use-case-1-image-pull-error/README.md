# Use Case 1: Image Pull Error

## Problem Description
This scenario simulates a very common error in production: attempting to deploy an application with a Docker image that doesn't exist or is not accessible. This can happen due to:
- Incorrect image name
- Wrong image tag
- Private repository without credentials
- Unreachable registry

## Simulated Scenario
A development team attempted to deploy a new version of their web application, but made an error in the image name in the deployment file.

## Problematic Deployment File
See `broken-deployment.yaml` - contains a reference to a non-existent image.

## Diagnostic Commands

### 1. Apply the deployment and observe the error
```bash
kubectl apply -f broken-deployment.yaml
```

### 2. Check the pod status
```bash
kubectl get pods -l app=webapp
```

### 3. View details of the problematic pod
```bash
kubectl describe pod <pod-name>
```

### 4. Check namespace events
```bash
kubectl get events --sort-by='.lastTimestamp'
```

## Expected Error
The pod will remain in `ImagePullBackOff` or `ErrImagePull` state with the error:
```
Failed to pull image "nginx:nonexistent-tag": rpc error: code = NotFound desc = failed to pull and unpack image
```

## Solution
1. Identify the correct image (see `fixed-deployment.yaml`)
2. Update the deployment with the correct image
3. Verify that the pod starts correctly

## Resolution Commands
```bash
# Apply the fix
kubectl apply -f fixed-deployment.yaml

# Verify that the pod is running
kubectl get pods -l app=webapp

# Check the application logs
kubectl logs -l app=webapp
```
