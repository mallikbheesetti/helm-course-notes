# Lab 06 - Umbrella Chart

## Goal

Build a parent Guestbook chart that packages frontend, backend, and
database as subcharts and installs the whole application as one release.

## Prerequisites

- Lab 05 chart (or a copy of it) for the frontend
- Lab 02 manifests as reference for backend and database

## Tasks

1. Create the parent chart:

   ```bash
   cd ~/helm-labs
   helm create guestbook-umbrella
   rm -rf guestbook-umbrella/templates/*
   ```

   Keep `templates/_helpers.tpl` only if you need parent helpers.

2. Create three subchart directories with their own `Chart.yaml`,
   `values.yaml`, and `templates/`:

   ```
   guestbook-umbrella/charts/
     frontend/
     backend/
     database/
   ```

3. Move the appropriate templates and values from Labs 02 and 05 into each
   subchart. Each subchart should be independently installable.

4. In the parent `values.yaml`, provide defaults for each subchart:

   ```yaml
   frontend:
     image:
       repository: nginx
       tag: "1.27"
     service:
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
     ingress:
       enabled: true
       host: backend.minikube.local

   database:
     enabled: true
     persistence:
       size: 1Gi
   ```

5. Add a parent `templates/ingress.yaml` if you want a single Ingress for
   both hosts, or let each subchart render its own.

6. Add parent `templates/NOTES.txt` with access instructions.

7. Validate and install:

   ```bash
   helm lint ./guestbook-umbrella
   helm template demo ./guestbook-umbrella
   helm install demo ./guestbook-umbrella -n lab06 --create-namespace
   helm list -n lab06
   kubectl -n lab06 get all,ingress,pvc,secret,configmap
   ```

8. Inspect what the parent rendered:

   ```bash
   helm get manifest demo -n lab06
   helm get values demo -n lab06 --all
   ```

## Hints

- Subchart templates receive the parent release name and namespace.
- Parent values under a subchart key override that subchart's defaults.
- Do not duplicate resource names across subcharts.
- Use the subchart name (or alias) as the values key.
- If a subchart has an Ingress, you may end up with several Ingress
  objects; that is fine as long as hosts are unique.

## Verify

```bash
helm lint ./guestbook-umbrella
helm template demo ./guestbook-umbrella
helm install demo ./guestbook-umbrella -n lab06 --create-namespace
kubectl -n lab06 get deploy,svc,ingress,pvc
helm get manifest demo -n lab06 | grep '^kind:'
```

Expected:

- The rendered manifest includes objects from all three subcharts.
- One installation creates the whole application.
- `helm uninstall demo -n lab06` removes all of it.

## Solution sketch

Parent `Chart.yaml`:

```yaml
apiVersion: v2
name: guestbook-umbrella
version: 0.1.0
appVersion: "2.0"
dependencies:
  - name: frontend
    version: 0.1.0
    repository: file://charts/frontend
  - name: backend
    version: 0.1.0
    repository: file://charts/backend
  - name: database
    version: 0.1.0
    repository: file://charts/database
    condition: database.enabled
```

Parent `values.yaml`:

```yaml
database:
  enabled: true

frontend:
  ingress:
    enabled: true

backend:
  ingress:
    enabled: true
```

Note: `file://charts/...` is useful for development, but subcharts placed
directly under `charts/` are already available without a dependency
entry. Choose one approach and be consistent.

## Stretch

- Add `condition` toggles for each subchart.
- Add a `global` value such as `environment: dev` used by all subcharts.
- Give one subchart an alias and install it twice.
- Package each subchart and reference the `.tgz` files.

## Cleanup

```bash
helm uninstall demo -n lab06
kubectl delete namespace lab06
```

## Reflection

What belongs in the parent chart versus a subchart? What is the trade-off
of a single umbrella release versus three independent releases?
