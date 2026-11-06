# Lab 03 - Install a Local Kubernetes Cluster

Source: upstream `lab3_kubernetes_install`.

The original course used older minikube and kubectl binaries. Use current
packages instead. The goal is the same: Docker + minikube + kubectl, with
an Ingress controller and local hostnames.

## Install the tools

macOS (Homebrew):

```bash
brew install minikube kubectl
```

Linux: follow the official minikube and kubectl installation pages for
your distribution. Do not copy the course's fixed `v1.20.2` kubectl
binary.

## Start minikube

```bash
docker version
minikube version
minikube start
minikube status
kubectl get nodes
```

## Enable Ingress

```bash
minikube addons enable ingress
kubectl -n ingress-nginx get pods
kubectl -n ingress-nginx get svc,endpoints
```

If you use a different Ingress controller, verify its admission webhook is
healthy before creating Ingress objects. A webhook with no endpoints
causes every Ingress apply to fail.

## Local DNS and tunnel

On macOS, run the tunnel in a separate terminal:

```bash
minikube tunnel
```

Add the lab hostnames to `/etc/hosts`:

```
127.0.0.1 frontend.minikube.local
127.0.0.1 backend.minikube.local
```

For release-prefixed hosts, add those too:

```
127.0.0.1 dev.frontend.minikube.local
127.0.0.1 test.frontend.minikube.local
```

## Verify the environment

```bash
kubectl get nodes
kubectl -n ingress-nginx get pods
kubectl api-resources | grep -i ingress
ping -c 1 frontend.minikube.local
```

## Notes

- `minikube tunnel` usually needs elevated privileges.
- Keep it running while testing Ingress hosts.
- `kubectl get nodes` must work before debugging Helm.
