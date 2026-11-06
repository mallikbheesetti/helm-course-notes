# Lab 04 - Install Helm and Clean Up

Source: upstream `lab4_helm_install`.

The original course installed Helm 3.1.1 and used `stable/mysql`. Use a
current Helm 3 or Helm 4 package and a maintained chart for the demo.

## Install Helm

macOS (Homebrew):

```bash
brew install helm
helm version
helm env
```

Linux: use the official Helm install script or your package manager.

## Verify cluster access

```bash
kubectl config current-context
kubectl config view --minify
kubectl get nodes
```

## Add a repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
helm search repo bitnami/mysql
```

The course used `stable`:

```bash
helm repo add stable https://charts.helm.sh/stable
```

`stable` is deprecated and many charts are unmaintained. Prefer Bitnami or
Artifact Hub.

## Install and inspect a demo release

```bash
helm install demo-mysql bitnami/mysql -n demo --create-namespace
helm list -n demo
helm status demo-mysql -n demo
kubectl -n demo get all,secret,pvc
```

## Clean up

```bash
kubectl -n demo get all
kubectl -n demo get secret
helm uninstall demo-mysql -n demo
kubectl -n demo get all
kubectl -n demo get secret
helm list -n demo
kubectl delete namespace demo
```

The point of the cleanup demo is to observe that Helm removes the release
objects and the release Secret while leaving the namespace in place.

## Removing the Helm client

Removing the local binary does not uninstall releases. Helm 3 stores
release metadata as Secrets in the cluster:

```bash
helm list -A
helm uninstall <release> -n <namespace>
```

MacOS/Linux local state locations:

```bash
helm env | grep HELM
rm -rf ~/.cache/helm ~/.config/helm ~/.local/share/helm
```
