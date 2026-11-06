# Raw Lab 01 - Guestbook v1

These are the Kubernetes manifests for the first Guestbook version:
a frontend Deployment, a Service, and an Ingress.

Source: upstream `lab1_kubectl_version1/yaml`.

## Apply

```bash
kubectl create namespace lab01
kubectl -n lab01 apply -f yaml/
kubectl -n lab01 get deploy,svc,ingress
```

Add the host to `/etc/hosts` and ensure an Ingress controller is running:

```
127.0.0.1 frontend.minikube.local
```

```bash
minikube tunnel
```

## Verify

```bash
kubectl -n lab01 get endpoints frontend
kubectl -n lab01 describe ingress guestbook-ingress
curl http://frontend.minikube.local
```

## Notes

- The Ingress was reduced to the frontend host because v1 has no backend.
- The frontend image is `phico/frontend:1.0`.
- The Service targets container port `4200`.

## Cleanup

```bash
kubectl delete namespace lab01
```
