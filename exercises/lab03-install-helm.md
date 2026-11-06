# Lab 03 - Install the Tooling

## Goal

Prepare a local Kubernetes environment for the rest of the labs and verify
that Helm can reach the cluster and repositories.

## Prerequisites

- Docker or another minikube driver
- Administrative access to edit `/etc/hosts` (for Ingress hostnames)

## Tasks

1. Install `minikube`, `kubectl`, and `helm` using your package manager.

2. Start a cluster:

   ```bash
   minikube start
   minikube status
   kubectl get nodes
   ```

3. Enable the Ingress addon or install ingress-nginx:

   ```bash
   minikube addons enable ingress
   kubectl -n ingress-nginx get pods
   ```

   If you use another Ingress controller, make sure its admission webhook
   is healthy before creating Ingress objects.

4. Start the tunnel in a second terminal:

   ```bash
   minikube tunnel
   ```

5. Add local hostnames to `/etc/hosts`:

   ```
   127.0.0.1 frontend.minikube.local
   127.0.0.1 backend.minikube.local
   ```

6. Verify Helm:

   ```bash
   helm version
   helm env
   helm list -A
   ```

7. Add a chart repository and search it:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   helm repo list
   helm search repo bitnami/mongodb
   ```

8. Confirm the Ingress API version the cluster serves:

   ```bash
   kubectl api-resources | grep -i ingress
   ```

## Verify

```bash
kubectl get nodes
kubectl -n ingress-nginx get pods
helm version
helm repo list
helm search repo bitnami/mongodb
kubectl api-resources | grep networking.k8s.io/v1
```

Expected:

- Node `Ready`.
- ingress-nginx controller pod `Running`.
- Helm client version prints.
- Bitnami repository is listed.
- A MongoDB chart appears in search results.
- `ingresses` is served by `networking.k8s.io/v1`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `minikube start` fails | Check Docker is running, then `minikube delete && minikube start` |
| No Ingress address | Ensure `minikube tunnel` is running |
| Host not resolving | Check `/etc/hosts` |
| Ingress webhook connection refused | Check ingress-nginx pods and endpoints |
| `kubectl` TLS timeout | Restart minikube, check VM/Docker health |

## Cleanup

Keep the cluster for the remaining labs. To reset it:

```bash
minikube stop
# or a full reset:
minikube delete
```

## Reflection

Why does Helm 3 need no server-side component? What replaced Tiller's
storage role?
