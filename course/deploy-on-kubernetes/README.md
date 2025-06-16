# Deploy on Kubernetes

## Resources

In the `deploy-on-kubernetes` folder are available the following examples:

- `pvc.yaml`: Defines a PersistentVolumeClaim (PVC) object that requests 3Gi of storage, to be used to attach one or more pods to persistent storage.
- `pv.yaml`: Defines a PersistentVolume (PV) object that provides the storage requested by the PVC, with a capacity of 3Gi and access mode set to `ReadWriteOnce`.
- `cronjob.yaml`: Example of a CronJob object that runs a job every minute using a `busybox` container that prints the date and a message.
- `pv.yaml` (presumably, although not directly shown): Defines a PersistentVolume (PV) that provides the storage requested by the PVC.
- `service.yaml` (presumably): May contain the definition of a Service to expose pods within the cluster or externally.
- `svc-lb.yaml`: Defines a Service object that exposes a set of pods using a LoadBalancer, allowing external access to the service.
- `svc-nodeport.yaml`: Defines a Service object that exposes a set of pods using NodePort, allowing external access to the service on a specific port.
- `nginx-ingress.yaml`: Defines an Ingress object that manages external access to services, allowing HTTP traffic to reach the specified service.
- `deployment.yaml`: Defines a Deployment object that manages a set of replicas of a pod running a `busybox` container, which prints the date and a message every minute.
- `pod.yaml`: Defines a Pod object that runs a `busybox` container, which prints the date and a message every minute.
- `configmap.yaml`: Defines a ConfigMap object that stores configuration data in key-value pairs, which can be used by pods.
- `configmap-file.yaml`: Defines a ConfigMap object that stores configuration data from a file, which can be used by pods.
- `secret.yaml`: Defines a Secret object that stores sensitive data, such as passwords or tokens, in a secure manner.
- `secret-file.yaml`: Defines a Secret object that stores sensitive data from a file, which can be used by pods.

All these examples are designed to demonstrate various Kubernetes objects and their configurations, which can be applied to a Kubernetes cluster. 

They are also OpenShift compatible, as OpenShift is built on top of Kubernetes and supports the same API objects.

## Official Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)