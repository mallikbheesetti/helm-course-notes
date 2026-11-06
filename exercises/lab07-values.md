# Lab 07 - Values and Overrides

> Reference implementation: [`labs/reference/lab07/guestbook`](../labs/reference/lab07/guestbook)

## Goal

Parameterize the Guestbook chart and practice every common way to supply
values: defaults, values files, `--set`, environment-specific files, and
subchart overrides.

## Prerequisites

- Lab 05 or 06 chart

## Tasks

1. Expand `values.yaml` with a clear hierarchy:

   ```yaml
   global:
     environment: dev

   frontend:
     replicaCount: 1
     image:
       repository: nginx
       tag: "1.27"
       pullPolicy: IfNotPresent
     service:
       type: ClusterIP
       port: 80
     ingress:
       enabled: true
       host: frontend.minikube.local

   backend:
     image:
       repository: nginx
       tag: "1.27"
     service:
       port: 80

   database:
     enabled: true
     image:
       repository: mongo
       tag: "7"
     persistence:
       size: 1Gi
   ```

2. Template the image, service type, port, replicas, and global
   environment labels in the manifests.

3. Render with defaults:

   ```bash
   helm template demo ./guestbook
   ```

4. Override with a values file:

   ```bash
   cat > values-dev.yaml <<'EOF'
   global:
     environment: dev
   frontend:
     replicaCount: 1
     ingress:
       host: dev.frontend.minikube.local
   EOF

   helm template demo ./guestbook -f values-dev.yaml
   ```

5. Create a production-shaped values file:

   ```bash
   cat > values-prod.yaml <<'EOF'
   global:
     environment: prod
   frontend:
     replicaCount: 3
     service:
       type: LoadBalancer
   database:
     persistence:
       size: 5Gi
   EOF

   helm template demo ./guestbook -f values-prod.yaml
   ```

6. Layer multiple values files:

   ```bash
   helm template demo ./guestbook -f values-dev.yaml -f values-prod.yaml
   ```

   Confirm the later file wins.

7. Override on the command line:

   ```bash
   helm template demo ./guestbook --set frontend.replicaCount=2
   helm template demo ./guestbook --set frontend.service.type=NodePort
   helm template demo ./guestbook --set-string frontend.image.tag=1.10
   ```

8. Install and inspect:

   ```bash
   helm install demo ./guestbook -n lab07 --create-namespace -f values-dev.yaml
   helm get values demo -n lab07
   helm get values demo -n lab07 --all
   ```

9. Upgrade with a new value and verify the change:

   ```bash
   helm upgrade demo ./guestbook -n lab07 -f values-prod.yaml
   kubectl -n lab07 get deploy -o wide
   ```

## Hints

- Values files are merged recursively; later files win for scalars.
- `--set` always wins over `-f`.
- For nested subchart values, use the subchart name as the top-level key.
- `helm get values` shows user-supplied values by default; `--all` shows
  computed values too.
- Use `--set-string` when values like `1.10` must not become `1.1`.

## Verify

```bash
helm template demo ./guestbook --set frontend.replicaCount=4 | grep -A2 replicas
helm template demo ./guestbook --set frontend.service.type=NodePort | grep -A2 'type:'
helm template demo ./guestbook -f values-prod.yaml | grep -E 'replicas|LoadBalancer|5Gi'
```

Expected: the rendered values match each override and the precedence is
`--set` > later `-f` > earlier `-f` > chart defaults.

## Solution sketch

```bash
helm template demo ./guestbook
helm template demo ./guestbook -f values-dev.yaml
helm template demo ./guestbook -f values-dev.yaml -f values-prod.yaml
helm template demo ./guestbook --set frontend.replicaCount=2
helm install demo ./guestbook -n lab07 --create-namespace -f values-dev.yaml
helm get values demo -n lab07 --all
```

## Stretch

- Add `values.schema.json` and try to install with an invalid service type.
- Use `--set-file` to inject a config file.
- Add a `global.imageRegistry` and prefix every image reference with it.
- Use `--reuse-values` versus an explicit values file and compare.

## Cleanup

```bash
helm uninstall demo -n lab07
kubectl delete namespace lab07
```

## Reflection

Why is `--set` convenient for experiments but problematic for production?
Which values should be environment-specific and which should stay in the
chart defaults?
