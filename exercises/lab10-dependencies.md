# Lab 10 - Dependencies, Packaging, and Repositories

> Reference implementation: [`labs/reference/lab10/guestbook`](../labs/reference/lab10/guestbook)

## Goal

Package a chart, create a local repository, declare dependencies, control
them with conditions and tags, and install from the repository.

## Prerequisites

- Lab 06 or 09 chart
- Network access for the Bitnami repository (optional)

## Part A - Package the chart

1. Lint and render:

   ```bash
   helm lint ./guestbook
   helm template demo ./guestbook
   ```

2. Package it:

   ```bash
   mkdir -p dist
   helm package ./guestbook --destination ./dist
   ls -l ./dist
   ```

3. Inspect the archive name. It should be
   `guestbook-<version>.tgz` using the `version` from `Chart.yaml`.

## Part B - Create a local repository

1. Generate the index:

   ```bash
   helm repo index ./dist --url http://127.0.0.1:8879
   cat ./dist/index.yaml
   ```

2. Serve it over HTTP from a second terminal:

   ```bash
   cd dist
   python3 -m http.server 8879
   ```

3. Add and use the repository:

   ```bash
   helm repo add local http://127.0.0.1:8879
   helm repo update
   helm search repo local/guestbook
   helm show chart local/guestbook
   helm show values local/guestbook
   ```

4. Install from the repository:

   ```bash
   helm install demo local/guestbook -n lab10 --create-namespace
   helm list -n lab10
   ```

## Part C - Declare dependencies

1. In the parent `Chart.yaml`, add dependencies using local subcharts:

   ```yaml
   dependencies:
     - name: frontend
       version: 0.1.0
       repository: file://charts/frontend
       condition: frontend.enabled
     - name: backend
       version: 0.1.0
       repository: file://charts/backend
       condition: backend.enabled
     - name: database
       version: 0.1.0
       repository: file://charts/database
       condition: database.enabled
       tags:
         - storage
   ```

2. Add toggles to `values.yaml`:

   ```yaml
   frontend:
     enabled: true
   backend:
     enabled: true
   database:
     enabled: true
   tags:
     storage: true
   ```

3. Resolve dependencies:

   ```bash
   helm dependency update ./guestbook
   helm dependency list ./guestbook
   cat ./guestbook/Chart.lock
   ```

4. Render with all dependencies, then with one disabled:

   ```bash
   helm template demo ./guestbook
   helm template demo ./guestbook --set database.enabled=false
   helm template demo ./guestbook --set tags.storage=false
   ```

5. Test condition vs tag precedence:

   ```bash
   # condition true should win over tag false
   helm template demo ./guestbook --set database.enabled=true --set tags.storage=false
   ```

6. Use a public dependency (optional). Add to `Chart.yaml`:

   ```yaml
   - name: mongodb
     version: ~15.6.0
     repository: https://charts.bitnami.com/bitnami
     condition: mongodb.enabled
   ```

   Then:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   helm dependency update ./guestbook
   helm template demo ./guestbook --set mongodb.enabled=true
   ```

## Part D - Export values (optional)

1. In a child chart's `values.yaml`:

   ```yaml
   exports:
     data:
       mongodb_uri:
         username: admin
         password: password
   ```

2. In the parent `Chart.yaml`:

   ```yaml
   import-values:
     - data
   ```

3. Use `{{ .Values.mongodb_uri.username }}` in the parent, or use the
   child/parent form:

   ```yaml
   import-values:
     - child: data
       parent: backend_data
   ```

   Then reference `{{ .Values.backend_data.mongodb_uri.username }}`.

## Hints

- `helm dependency update` downloads all declared dependencies regardless
  of conditions and tags.
- Conditions and tags only affect what gets installed.
- `helm dependency build` uses `Chart.lock` and does not re-resolve ranges.
- Commit `Chart.lock`; decide deliberately whether to vendor `charts/`.
- Conditions override tags.
- Use `file://` for local chart directories, or copy subcharts directly
  under `charts/`.

## Verify

```bash
helm dependency list ./guestbook
helm template demo ./guestbook --set database.enabled=false | grep -c 'kind:'
helm template demo ./guestbook --set database.enabled=true | grep -c 'kind:'
helm search repo local/guestbook
helm install demo local/guestbook -n lab10 --create-namespace
helm list -n lab10
```

Expected:

- `helm dependency list` shows all dependencies as `ok`.
- Disabling the database reduces the rendered object count.
- The local repository serves the packaged chart.
- Install from `local/guestbook` succeeds.

## Solution sketch

```bash
helm package ./guestbook --destination ./dist
helm repo index ./dist --url http://127.0.0.1:8879
(cd dist && python3 -m http.server 8879) &
helm repo add local http://127.0.0.1:8879
helm repo update
helm dependency update ./guestbook
helm dependency build ./guestbook
helm install demo local/guestbook -n lab10 --create-namespace
```

## Stretch

- Add a dependency alias and install the same chart twice.
- Sign and verify a package with `helm package --sign` and `helm verify`.
- Publish the repository to a static host or ChartMuseum.
- Add `values.schema.json` to the parent and validate subchart values.

## Cleanup

```bash
helm uninstall demo -n lab10
kubectl delete namespace lab10
helm repo remove local
# stop the http.server process in the other terminal
```

## Reflection

Why does `helm dependency update` download disabled dependencies? What is
the difference between `update` and `build` in CI?
