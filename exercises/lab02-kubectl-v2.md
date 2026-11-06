# Lab 02 - Guestbook v2 with `kubectl`

## Goal

Deploy the full three-tier Guestbook with raw Kubernetes manifests:
frontend, backend API, and MongoDB with Secrets, Services, an Ingress,
and persistent storage.

## Prerequisites

- Lab 01 completed or equivalent cluster access
- An Ingress controller
- A default StorageClass (minikube provides one)

## Architecture

```
Ingress
  |-- frontend.minikube.local -> frontend Service -> frontend Pod
  |                              (ConfigMap configuration)
  |
  `-- backend.minikube.local  -> backend Service  -> backend Pod
                                                     | (Secret: Mongo URI)
                                                     v
                                             mongodb Service -> mongodb Pod
                                                                 | (Secret: root password)
                                                                 v
                                                         PVC -> PV
```

## Tasks

1. Create namespace `lab02`.
2. Create a Secret `mongodb-secret` with a MongoDB root username and
   password. Use `stringData` for readability.
3. Create a PersistentVolumeClaim `mongodb-pvc` requesting `1Gi` with
   `ReadWriteOnce`.
4. Deploy MongoDB using `mongo:7`, mounting the PVC at
   `/data/db`, and expose it as Service `mongodb` on port `27017`.
5. Create a Secret `backend-secret` containing a MongoDB connection URI
   such as
   `mongodb://admin:password@mongodb:27017/guestbook?authSource=admin`.
6. Deploy the backend API (any simple image or a placeholder such as
   `nginx:1.27` if you do not have the course image). Expose it as
   Service `backend` on port `80`.
7. Create a ConfigMap `frontend-config` with a key such as
   `GUESTBOOK_TITLE=Concert for Climate`.
8. Deploy the frontend and expose it as Service `frontend` on port
   `80`.
9. Create one Ingress with both hosts:
   - `frontend.minikube.local` -> `frontend:80`
   - `backend.minikube.local` -> `backend:80`
10. Apply everything and verify.

## Hints

- Use `envFrom` or `env.valueFrom.secretKeyRef` to inject secrets.
- Use `persistentVolumeClaim.claimName` in the Pod volume.
- Services select Pods by label; make labels consistent.
- If you use Deployments, remember `spec.selector.matchLabels` must match
  `spec.template.metadata.labels`.
- The Ingress API is `networking.k8s.io/v1` with `pathType: Prefix`.
- Check `kubectl get pvc` if MongoDB is stuck in `Pending`.

## Verify

```bash
kubectl -n lab02 get all
kubectl -n lab02 get pvc,secret,configmap
kubectl -n lab02 get endpoints
kubectl -n lab02 describe ingress guestbook-ingress
kubectl -n lab02 logs deploy/mongodb
kubectl -n lab02 logs deploy/backend
```

Expected:

- All Pods `Running` and ready.
- PVC `Bound`.
- Endpoints populated for all Services.
- Ingress has two hosts with correct backends.

## Solution sketch

Secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
stringData:
  username: admin
  password: password
---
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
type: Opaque
stringData:
  mongodb-uri: mongodb://admin:password@mongodb:27017/guestbook?authSource=admin
```

PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

MongoDB Deployment excerpt:

```yaml
spec:
  containers:
    - name: mongodb
      image: mongo:7
      ports:
        - containerPort: 27017
      env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: password
      volumeMounts:
        - name: data
          mountPath: /data/db
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: mongodb-pvc
```

Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook-ingress
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
    - host: backend.minikube.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 80
```

## Stretch

- Add resource requests and limits.
- Add readiness and liveness probes.
- Replace the Pod with a Deployment and scale the frontend to 3 replicas.
- Add a ConfigMap volume instead of environment variables.

## Cleanup

```bash
kubectl delete namespace lab02
```

## Reflection

List every object you created and classify it by tier. This inventory is
what you will turn into charts in Lab 05 and Lab 06.
