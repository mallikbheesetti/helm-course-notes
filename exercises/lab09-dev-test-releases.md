# Lab 09 - Dev and Test Releases

> Reference implementation: [`labs/reference/lab09/guestbook`](../labs/reference/lab09/guestbook)

## Goal

Run the same chart as two independent releases in two namespaces, with
different values, names, and hostnames.

## Prerequisites

- Lab 08 chart

## Tasks

1. Create two namespaces:

   ```bash
   kubectl create namespace dev
   kubectl create namespace test
   ```

2. Create two values files.

   `values-dev.yaml`:

   ```yaml
   global:
     environment: dev
   frontend:
     replicaCount: 1
     ingress:
       enabled: true
       hosts:
         - host: dev.frontend.minikube.local
           service: frontend
           port: 80
           paths:
             - path: /
   database:
     persistence:
       size: 1Gi
   ```

   `values-test.yaml`:

   ```yaml
   global:
     environment: test
   frontend:
     replicaCount: 2
     ingress:
       enabled: true
       hosts:
         - host: test.frontend.minikube.local
           service: frontend
           port: 80
           paths:
             - path: /
   database:
     persistence:
       size: 2Gi
   ```

3. Install both releases:

   ```bash
   helm install dev ./guestbook -n dev -f values-dev.yaml
   helm install test ./guestbook -n test -f values-test.yaml
   ```

4. List and compare:

   ```bash
   helm list -A
   helm list -n dev
   helm list -n test
   helm get values dev -n dev --all
   helm get values test -n test --all
   ```

5. Verify resource names include the release name and live in the correct
   namespace:

   ```bash
   kubectl -n dev get deploy,svc,ingress
   kubectl -n test get deploy,svc,ingress
   helm get manifest dev -n dev | grep '^  name:'
   helm get manifest test -n test | grep '^  name:'
   ```

6. Upgrade only `test`:

   ```bash
   helm upgrade test ./guestbook -n test -f values-test.yaml --set frontend.replicaCount=3
   helm history test -n test
   helm history dev -n dev
   ```

7. Add the hostnames to `/etc/hosts`:

   ```
   127.0.0.1 dev.frontend.minikube.local
   127.0.0.1 test.frontend.minikube.local
   ```

8. Test both hosts through the Ingress if your controller is running.

9. Uninstall one release and confirm the other is unaffected:

   ```bash
   helm uninstall dev -n dev
   helm list -A
   kubectl -n test get deploy,svc,ingress
   ```

## Hints

- Release names are unique per namespace, not globally.
- The same chart version can produce different manifests in each release
  because `.Release.Name`, `.Release.Namespace`, and values differ.
- Avoid hard-coded names; use `.Release.Name` and `.Release.Namespace`.
- If the Ingress host is release-prefixed, values can use
  `{{ .Release.Name }}` in the host template or you can set the full host
  per environment.

## Verify

```bash
helm list -A
kubectl -n dev get all,ingress
kubectl -n test get all,ingress
helm get manifest dev -n dev | grep -c 'dev-'
helm get manifest test -n test | grep -c 'test-'
```

Expected:

- Two releases, each with its own revision history.
- Resource names are prefixed by the release name.
- Objects live only in their release namespace.
- Upgrading or uninstalling one does not touch the other.

## Solution sketch

```bash
helm install dev ./guestbook -n dev -f values-dev.yaml
helm install test ./guestbook -n test -f values-test.yaml
helm list -A
helm upgrade test ./guestbook -n test -f values-test.yaml --set frontend.replicaCount=3
helm uninstall dev -n dev
```

## Stretch

- Install a third release `staging` in the `dev` namespace with a
  different release name.
- Use `--set` to change only the replica count in one release.
- Add a `global.environment` label and confirm it reaches every subchart.
- Compare `helm get manifest` output between dev and test with `diff`.

## Cleanup

```bash
helm uninstall dev -n dev
helm uninstall test -n test
kubectl delete namespace dev
kubectl delete namespace test
```

## Reflection

Why is it useful to model environments as separate releases rather than
separate charts? What should be shared between them?
