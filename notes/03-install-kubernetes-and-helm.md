# 03 - Installing Kubernetes and Helm

Source: `04/installing-a-local-kubernetes-cluster-with-helm-slides.pdf`

## Lab environment

The course runs everything locally:

```
Docker
  |
  v
minikube -> Kubernetes cluster
             ^
             |
       kubectl, helm
```

Required tools:

- Docker (or another supported minikube driver)
- `minikube`
- `kubectl`
- `helm`

## Install and start minikube

```bash
# macOS example
brew install minikube kubectl helm

minikube start
minikube status
kubectl cluster-info
kubectl get nodes
```

On macOS, the course also uses `minikube tunnel` so that Ingress and
LoadBalancer addresses are reachable from the host.

```bash
minikube tunnel
```

Keep `minikube tunnel` running in its own terminal. It requires elevated
privileges on some systems because it manipulates host routes.

## Local DNS for Ingress hosts

The Guestbook Ingress uses hostnames. Map them to localhost in
`/etc/hosts`:

```
127.0.0.1 frontend.minikube.local
127.0.0.1 backend.minikube.local
```

The exact hostnames depend on your values. A release-prefixed scheme such
as `dev.frontend.minikube.local` is common when running multiple releases.
Add every host you intend to test.

## Install Helm

Verify the client:

```bash
helm version
helm env
```

Useful environment variables and paths:

| Variable | Purpose |
| --- | --- |
| `HELM_CACHE_HOME` | Cache directory |
| `HELM_CONFIG_HOME` | Configuration directory |
| `HELM_DATA_HOME` | Data directory (repository cache) |
| `KUBECONFIG` | Kubernetes client configuration |

## Add repositories

Helm 3 ships with no default repository. Add the repositories you need:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
```

The course historically added `stable`:

```bash
helm repo add stable https://charts.helm.sh/stable
```

`stable` is no longer maintained and many charts are deprecated. Prefer
Bitnami or Artifact Hub for current charts.

## Cleaning a Helm installation

The course shows how to remove Helm itself from a workstation. The idea is
to remove the binary and the local Helm state:

```bash
# macOS/Linux examples
rm -f "$(which helm)"
rm -rf ~/.cache/helm ~/.config/helm ~/.local/share/helm
```

Helm 2 stored cluster-side state via Tiller. Helm 3 stores release state
as Secrets in the cluster. Removing the local client does not
automatically remove releases; uninstall releases first:

```bash
helm list --all-namespaces
helm uninstall <release> -n <namespace>
```

## Helm 2 and Tiller (historical)

Helm 2 required a server-side Tiller:

```bash
helm init
kubectl get deploy -n kube-system tiller-deploy
```

Tiller needed a service account and RBAC permissions. This is why Helm 2
installations often included a dedicated Tiller service account and
cluster role binding. In Helm 3 this whole layer is gone.

Do not use Tiller in new environments. The course mentions it so you can
recognize older installations.

## Verify the environment

```bash
kubectl version --client
kubectl get nodes
helm version
helm repo list
helm search repo bitnami/mongodb
```

Expected: the node is `Ready`, Helm reports a version, and a repository
search returns results.

## Common setup issues

| Symptom | Likely cause | Check |
| --- | --- | --- |
| `minikube start` fails | Docker/VM driver problem | `minikube status`, `minikube logs` |
| Ingress host unreachable | No tunnel or no `/etc/hosts` entry | `minikube tunnel`, `getent hosts` / `ping` |
| `kubectl` TLS timeout | API server or VM unhealthy | `minikube status`, restart cluster |
| `helm repo` empty | Helm 3 has no defaults | `helm repo add ...` |
| Chart install fails on Ingress | API version or admission webhook | See `notes/troubleshooting.md` |

## Key takeaways

- The course environment is minikube + kubectl + Helm.
- `minikube tunnel` and `/etc/hosts` are needed for local Ingress hosts.
- Helm 3 has no default repository.
- Helm 2's Tiller is historical; Helm 3 talks directly to the API.
