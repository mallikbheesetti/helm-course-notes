# 07 - Using Existing Charts

Source: `08/using-existing-helm-chart-slides.pdf`

## From source to hub

The packaging evolution mirrors other package ecosystems:

```
sources -> packages -> repositories -> hub
```

| Concept | Helm | Docker | Java | JavaScript |
| --- | --- | --- | --- | --- |
| Definition file | Kubernetes YAML | System files | `file.java` | `file.js` |
| Package | Chart | Image | Jar/Ear | Module |
| Tool | Helm | Docker | Maven | npm |
| Metadata | `Chart.yaml` | `Dockerfile` | `pom.xml` | `package.json` |
| Repository | Helm repository | Docker registry | Maven repository | npm registry |
| Public hub | Artifact Hub | Docker Hub | Maven Central | npmjs.com |

## Finding charts

Current public discovery:

- <https://artifacthub.io/> - searchable index across many repositories
- <https://hub.helm.sh/> - legacy Helm hub

The course also mentions the `stable` repository:

```bash
helm repo add stable https://charts.helm.sh/stable
```

`stable` is deprecated and not maintained. Many old examples still work,
but prefer the original chart repository or Bitnami:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## Repository commands

```bash
helm repo add <name> <url>
helm repo list
helm repo update
helm repo remove <name>
```

`helm repo update` refreshes local indexes so searches and installs see
new versions.

> Do not confuse `helm repo update` (repository indexes) with
> `helm dependency update` (charts a chart depends on).

## Search and inspect

```bash
helm search hub wordpress
helm search repo wordpress
helm search repo bitnami/wordpress --versions

helm show chart bitnami/wordpress
helm show values bitnami/wordpress
helm show readme bitnami/wordpress
helm show all bitnami/wordpress
```

Older aliases you may see in course material:

| Older command | Current command |
| --- | --- |
| `helm search hub <keyword>` | Same (Artifact Hub search) |
| `helm inspect all <chart>` | `helm show all <chart>` |
| `helm inspect values <chart>` | `helm show values <chart>` |
| `helm fetch <chart>` | `helm pull <chart>` |

## Install an existing chart

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install my-mongodb bitnami/mongodb -n mongodb --create-namespace
helm list -n mongodb
helm status my-mongodb -n mongodb
```

The Wordpress demo from the course:

```bash
helm install my-blog bitnami/wordpress \
  --namespace blog \
  --create-namespace \
  --set wordpressUsername=admin \
  --set wordpressPassword='ChangeMe123!' \
  --set mariadb.auth.rootPassword='RootChangeMe123!'
```

Check the notes Helm prints after installation for the access URL and
credentials. Never bake real passwords into committed files.

## Customizing an existing chart

The most important command is:

```bash
helm show values bitnami/mongodb > mongodb-values.yaml
```

Edit only the values you need, then install or upgrade with `-f`:

```bash
helm install my-mongodb bitnami/mongodb -n mongodb --create-namespace -f mongodb-values.yaml
helm upgrade my-mongodb bitnami/mongodb -n mongodb -f mongodb-values.yaml
```

Use `--set` for one-off experiments:

```bash
helm upgrade my-mongodb bitnami/mongodb -n mongodb \
  --reuse-values \
  --set replicaCount=3
```

Caution with `--reuse-values`: it reuses the previous release values and
ignores changes to the chart's own defaults. Prefer an explicit values
file in production.

### Values and subcharts

For an umbrella chart that depends on an existing chart, nest the child
values under the dependency name:

```yaml
# parent values.yaml
mongodb:
  architecture: standalone
  auth:
    rootPassword: change-me
```

If the child is aliased, use the alias as the key.

### Exporting and importing values

A child chart can export computed values to the parent:

```yaml
# child values.yaml
exports:
  data:
    mongodb_uri:
      username: admin
      password: password
```

Parent `Chart.yaml`:

```yaml
dependencies:
  - name: backend
    version: ~1.2.1
    repository: https://charts.example.com
    import-values:
      - data
```

Or map to a specific parent key:

```yaml
    import-values:
      - child: data
        parent: backend_data
```

### Global values

Globals are visible to the parent and all subcharts:

```yaml
global:
  imageRegistry: registry.example.com
  environment: dev
```

```yaml
# in any chart
image: {{ .Values.global.imageRegistry }}/app:latest
```

## Inspecting what will change

Before upgrading a chart you did not write:

```bash
helm get values my-release -n my-namespace > current-values.yaml
helm diff upgrade my-release bitnami/mongodb -n my-namespace -f new-values.yaml
```

The `helm diff` command is a plugin, not built into Helm. If it is not
installed, use `helm template` with the old and new values and compare the
output, or use `helm upgrade --dry-run --debug`.

## Pulling a chart for inspection

```bash
helm pull bitnami/mongodb --untar --untardir ./vendor
ls -R ./vendor/mongodb
```

This is useful when you need to read templates, understand defaults, or
vendor a chart into your own repository.

## Upgrading and rolling back third-party charts

```bash
helm upgrade my-mongodb bitnami/mongodb -n mongodb -f mongodb-values.yaml
helm history my-mongodb -n mongodb
helm rollback my-mongodb 1 -n mongodb
```

Read the chart's changelog and release notes before a major version
upgrade. Existing charts often have migration requirements (database
upgrades, value renames, immutable field changes).

## Third-party chart checklist

1. `helm search repo <chart>` - confirm the chart and versions.
2. `helm show chart` and `helm show readme` - check requirements and
   deprecations.
3. `helm show values > values.yaml` - start from the real defaults.
4. Read the chart's NOTES and any migration notes.
5. `helm template` or `--dry-run` - inspect rendered manifests.
6. Install into a dedicated namespace.
7. Store your overrides in version control, excluding secrets.
8. Pin the chart version for reproducibility.

## Key takeaways

- Artifact Hub and Bitnami are the practical sources for current charts.
- `helm show values` is the starting point for customization.
- Override child values under the dependency/alias key.
- Use `import-values` and globals to wire charts together.
- Pin versions and always inspect an upgrade before applying it.
