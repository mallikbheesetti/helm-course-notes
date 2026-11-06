# Lab 11 - Use an Existing Chart

> Reference implementation: [`labs/reference/lab11/guestbook`](../labs/reference/lab11/guestbook)

## Goal

Find, inspect, install, customize, upgrade, and remove a third-party chart
from a public repository. The course uses MongoDB and Wordpress; this lab
uses Bitnami.

## Prerequisites

- Working cluster with a default StorageClass
- Network access to `https://charts.bitnami.com/bitnami`

## Part A - Find and inspect

1. Add the repository:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

2. Search:

   ```bash
   helm search repo mongodb
   helm search repo bitnami/mongodb --versions | head
   ```

3. Inspect:

   ```bash
   helm show chart bitnami/mongodb
   helm show readme bitnami/mongodb | head -80
   helm show values bitnami/mongodb > mongodb-values.yaml
   ```

4. Read the values file and identify:

   - Architecture (`standalone` vs `replicaSet`)
   - Authentication values
   - Persistence settings
   - Resource requests/limits
   - Service settings

5. Pull and inspect templates (optional):

   ```bash
   helm pull bitnami/mongodb --untar --untardir ./vendor
   ls ./vendor/mongodb/templates
   ```

## Part B - Install and customize

1. Create a minimal overrides file. Keep it free of real secrets:

   ```yaml
   # mongodb-values.yaml
   architecture: standalone
   auth:
     enabled: true
     rootUser: admin
     rootPassword: change-me
     database: guestbook
   persistence:
     enabled: true
     size: 1Gi
   resources:
     requests:
       cpu: 100m
       memory: 256Mi
     limits:
       cpu: 500m
       memory: 512Mi
   ```

2. Render before installing:

   ```bash
   helm template demo bitnami/mongodb -f mongodb-values.yaml > rendered.yaml
   less rendered.yaml
   ```

3. Install:

   ```bash
   helm install demo bitnami/mongodb -n lab11 --create-namespace -f mongodb-values.yaml
   helm list -n lab11
   helm status demo -n lab11
   ```

4. Inspect:

   ```bash
   kubectl -n lab11 get all,pvc,secret
   kubectl -n lab11 get endpoints
   helm get values demo -n lab11
   helm get manifest demo -n lab11 | head -60
   ```

## Part C - Upgrade and roll back

1. Change a value, for example persistence size or resources, then:

   ```bash
   helm upgrade demo bitnami/mongodb -n lab11 -f mongodb-values.yaml \
     --set resources.requests.memory=384Mi
   helm history demo -n lab11
   ```

2. Roll back:

   ```bash
   helm rollback demo 1 -n lab11
   helm history demo -n lab11
   ```

3. Verify the release state:

   ```bash
   helm status demo -n lab11
   helm get values demo -n lab11
   ```

## Part D - Use the chart inside your own chart (optional)

1. Add the dependency to a parent chart:

   ```yaml
   dependencies:
     - name: mongodb
       version: ~15.6.0
       repository: https://charts.bitnami.com/bitnami
       condition: mongodb.enabled
   ```

2. Add parent values under the dependency key:

   ```yaml
   mongodb:
     enabled: true
     architecture: standalone
     auth:
       rootUser: admin
       rootPassword: change-me
       database: guestbook
     persistence:
       enabled: true
       size: 1Gi
   ```

3. Resolve and render:

   ```bash
   helm dependency update ./guestbook
   helm template demo ./guestbook --set mongodb.enabled=true
   ```

4. If the chart exports values, import them in `Chart.yaml`:

   ```yaml
   import-values:
     - child: data
       parent: mongodb_data
   ```

   Then use them in the parent templates.

## Part E - Wordpress (optional)

```bash
helm install blog bitnami/wordpress -n blog --create-namespace \
  --set wordpressUsername=admin \
  --set wordpressPassword='ChangeMe123!' \
  --set mariadb.auth.rootPassword='RootChangeMe123!'

helm status blog -n blog
kubectl -n blog get svc
```

Read the printed notes for the access URL. Do not commit the passwords.

## Hints

- Start from `helm show values`, not from a blog post.
- Override only what you need; keep the rest of the chart defaults.
- Child values are nested under the dependency name or alias.
- Pin versions for reproducibility.
- Third-party charts can change values between major versions; read the
  chart changelog before upgrading.
- If an upgrade fails on immutable fields, you may need to uninstall and
  reinstall (with data-loss awareness) or migrate.

## Verify

```bash
helm list -n lab11
helm status demo -n lab11
kubectl -n lab11 get pods,pvc,svc
kubectl -n lab11 get endpoints
helm history demo -n lab11
```

Expected:

- MongoDB Pod is Running.
- PVC is Bound.
- Service endpoints are populated.
- History shows install, upgrade, and rollback revisions.

## Solution sketch

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm show values bitnami/mongodb > mongodb-values.yaml
# edit values
helm template demo bitnami/mongodb -f mongodb-values.yaml
helm install demo bitnami/mongodb -n lab11 --create-namespace -f mongodb-values.yaml
helm upgrade demo bitnami/mongodb -n lab11 -f mongodb-values.yaml --set resources.requests.memory=384Mi
helm history demo -n lab11
helm rollback demo 1 -n lab11
helm uninstall demo -n lab11
kubectl delete namespace lab11
```

## Stretch

- Install the same chart twice with different release names and values.
- Use `--reuse-values` once and explain why it can be dangerous.
- Compare `helm template` output before and after an upgrade.
- Install a chart from Artifact Hub that is not in Bitnami.
- Add the MongoDB chart as a subchart to your Guestbook umbrella.

## Cleanup

```bash
helm uninstall demo -n lab11
helm uninstall blog -n blog 2>/dev/null || true
kubectl delete namespace lab11
kubectl delete namespace blog 2>/dev/null || true
```

## Reflection

What did you have to know before installing the chart? Which values were
safe to override, and which could break the application?
