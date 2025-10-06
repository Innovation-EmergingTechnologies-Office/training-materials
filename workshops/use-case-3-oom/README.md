# Use Case 3: Out of Memory (OOMKilled)

## Problem Description
This scenario simulates an application that consumes more memory than allocated, causing the container to be terminated by the Linux kernel (OOMKilled). This is a critical problem in production that can cause:
- Loss of unsaved data
- Service interruptions
- Node performance degradation
- Overall cluster instability

## Simulated Scenario
A Java data processing application has a memory leak that causes increasing memory consumption until it exceeds the set limits. The application simulates loading large datasets into memory without properly releasing it.

## Problematic Deployment File
See `memory-hungry-app.yaml` - application with memory limits too low for the workload.

## Diagnostic Commands

### 1. Apply the deployment and monitor usage
```bash
kubectl apply -f memory-hungry-app.yaml
```

### 2. Monitor pods in real-time
```bash
kubectl get pods -l app=memory-app -w
```

### 3. Check details of the OOMKilled pod
```bash
kubectl describe pod <pod-name>
```

### 4. Analyze logs before the crash
```bash
kubectl logs <pod-name> --previous
```

### 5. Monitor resource usage
```bash
kubectl top pods -l app=memory-app
kubectl top nodes
```

### 6. Check OOM events
```bash
kubectl get events --field-selector reason=OOMKilling
```

## Expected Error
The pod will show:
- State: `OOMKilled` or continuous restarts
- Exit Code: 137 (SIGKILL)
- Reason: `OOMKilled` in events
- Memory usage increasing up to the limit

## Solution
1. Analyze memory usage patterns
2. Increase resource limits appropriately
3. Implement monitoring and alerting
4. Optimize the application for memory usage

## Resolution Commands
```bash
# Apply the fix with adequate limits
kubectl apply -f fixed-memory-app.yaml

# Monitor the stabilized usage
kubectl top pods -l app=memory-app

# Verify the stable application logs
kubectl logs -l app=memory-app

# Set up monitoring (optional)
kubectl apply -f monitoring.yaml
```
