# Raw Lab 02 - Guestbook v2

These are the Kubernetes manifests for the full three-tier Guestbook:
frontend, backend API, and MongoDB with a Secret and persistent storage.

Source: upstream `lab2_kubectl_version2/yaml`.

## Apply

```bash
kubectl create namespace lab02
kubectl -n lab02 apply -f yaml/
```

Or use the provided scripts from inside `yaml/`:

```bash
cd yaml
./create.sh
```

`create.sh` uses `kubectl create`; it is not idempotent. Prefer
`kubectl apply -f .` when re-running.

## Verify

```bash
kubectl -n lab02 get deploy,svc,ingress,pvc,secret,configmap
kubectl -n lab02 get endpoints
kubectl -n lab02 logs deploy/mongodb
kubectl -n lab02 logs deploy/backend
```

The Ingress exposes:

- `frontend.minikube.local`
- `backend.minikube.local`

Add both to `/etc/hosts` and run `minikube tunnel`.

## Notes

- MongoDB uses a manually provisioned PV/PVC with `storageClassName:
  manual`, matching the source lab.
- Secrets are base64-encoded in the manifests. They are lab credentials,
  not production secrets.
- Images are `phico/frontend:2.0`, `phico/backend:2.0`, and `mongo`.

## Cleanup

```bash
kubectl delete namespace lab02
```

Do not use `yaml/delete.sh` as-is if you applied into a non-default
namespace; namespace deletion is simpler and complete.
