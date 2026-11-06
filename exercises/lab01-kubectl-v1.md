# Lab 01 - Guestbook v1 with `kubectl`

## Goal

Deploy the first version of the Guestbook application using only
`kubectl`: one frontend Pod, one Service, and one Ingress.

## Prerequisites

- A working cluster (`kubectl get nodes`)
- An Ingress controller installed (for example ingress-nginx)

## Tasks

1. Create a namespace:

   ```bash
   kubectl create namespace lab01
   kubectl config set-context --current --namespace=lab01
   ```

2. Create a Pod named `frontend` running `nginx:1.27` with label
   `app: frontend` and container port `80`.

3. Create a Service named `frontend` that selects `app: frontend` and
   exposes port `80` to target port `80`.

4. Create an Ingress named `frontend-ingress` with host
   `frontend.minikube.local` and path `/` forwarding to the `frontend`
   Service on port `80`.

5. Apply everything:

   ```bash
   kubectl apply -f pod.yaml
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml
   ```

6. Inspect the objects:

   ```bash
   kubectl get pods,svc,ingress
   kubectl describe ingress frontend-ingress
   kubectl get endpoints frontend
   ```

## Hints

- Modern clusters require `apiVersion: networking.k8s.io/v1` for Ingress.
- `pathType` is mandatory in `networking.k8s.io/v1`.
- The Ingress backend structure is:

  ```yaml
  backend:
    service:
      name: frontend
      port:
        number: 80
  ```

- Add `127.0.0.1 frontend.minikube.local` to `/etc/hosts` and run
  `minikube tunnel` if you want to test from your machine.

## Verify

```bash
kubectl get pod frontend -o wide
kubectl get svc frontend
kubectl get ingress frontend-ingress
kubectl get endpoints frontend
```

Expected:

- Pod is `Running`.
- Service has a ClusterIP.
- Endpoints lists the Pod IP on port 80.
- Ingress shows the host and backend.

## Solution sketch

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  containers:
    - name: frontend
      image: nginx:1.27
      ports:
        - containerPort: 80
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
spec:
  rules:
    - host: frontend.minikube.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

## Stretch

- Add a second path `/api` pointing to a different Service.
- Change the Service to `NodePort` and reach it directly.
- Delete the pod and observe the Service endpoints update.

## Cleanup

```bash
kubectl delete namespace lab01
kubectl config set-context --current --namespace=default
```
