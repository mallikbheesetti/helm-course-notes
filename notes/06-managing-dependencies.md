# 06 - Managing Dependencies

Source: `07/managing-dependencies-slides.pdf`

## Packaging a chart

A chart directory can be used directly, but publishing requires an
archive. Helm packages a chart as a versioned `.tar.gz`:

```
chart_name-1.2.0.tgz
```

Package it:

```bash
helm package chart_name
# equivalent to:
tar -zcvf chart_name-1.2.0.tgz chart_name
```

`helm package` reads `Chart.yaml` and uses its `name` and `version` for
the archive filename. You can override the destination and version:

```bash
helm package mychart --destination ./dist
helm package mychart --version 1.2.1 --app-version 2.4.0
```

Before packaging, verify:

```bash
helm lint mychart
helm template demo mychart
```

Also review `.helmignore` to ensure unwanted files are excluded
(`.git`, editor files, test fixtures, local secrets).

## Helm repository layout

A repository is an HTTP server with:

```
repo/
  index.yaml
  frontend-1.2.0.tgz
  backend-1.2.2.tgz
  database-1.2.2.tgz
```

`index.yaml` is the repository catalog. It lists chart versions and the
URLs of their archives. The chart archives and `index.yaml` must be
served over HTTP/HTTPS.

Create or refresh the index:

```bash
helm repo index . --url https://charts.example.com
```

If `--url` is omitted, URLs are relative. Relative URLs work when the
client fetches the index from the same location as the archives.

Upload the archives and `index.yaml` to any static HTTP server: Nginx,
Apache, object storage, GitHub Pages, or a chart server such as
ChartMuseum.

## Using a repository

```bash
helm repo add myrepo https://charts.example.com
helm repo list
helm repo update

helm search repo myrepo/mychart
helm search repo mychart --versions

helm show chart myrepo/mychart
helm show values myrepo/mychart
helm show readme myrepo/mychart
helm show all myrepo/mychart

helm pull myrepo/mychart --version 1.2.0
helm install demo myrepo/mychart --version 1.2.0
```

Notes:

- `helm search hub` searches Artifact Hub; `helm search repo` searches
  locally configured repositories.
- `helm pull` is the current command; `helm fetch` is an older alias.
- `helm inspect` is an older alias for `helm show`.
- Pin versions in automation. Do not rely on "latest".

## Dependency declarations

In Helm 3, dependencies live in `Chart.yaml`:

```yaml
apiVersion: v2
name: guestbook
version: 1.0.0
appVersion: "2.0"

dependencies:
  - name: frontend
    version: 1.2.0
    repository: https://charts.example.com
  - name: backend
    version: ~1.2.2
    repository: https://charts.example.com
  - name: database
    version: 1.2.x
    repository: file://../database
    condition: database.enabled
    tags:
      - storage
```

Helm 2 used `requirements.yaml` for this. Helm 3 still reads legacy
charts, and `helm create` does not create a `requirements.yaml`, but do
not use it for new charts.

### Local dependencies

A `file://` URL points at a chart directory or archive relative to the
parent chart:

```yaml
dependencies:
  - name: frontend
    version: 1.2.0
    repository: file://../frontend
```

You can also copy unpacked charts directly into `charts/`. Helm will use
them as subcharts, but `helm dependency` commands will not manage them the
same way. Prefer a declared dependency for anything versioned or shared.

### Aliases

Use `alias` to install the same chart more than once:

```yaml
dependencies:
  - name: postgresql
    alias: primary
    version: 15.x.x
    repository: https://charts.bitnami.com/bitnami
  - name: postgresql
    alias: replica
    version: 15.x.x
    repository: https://charts.bitnami.com/bitnami
```

## Semantic version ranges

| Range | Matches |
| --- | --- |
| `1.2.3` | Exactly 1.2.3 |
| `~1.2.3` | `>= 1.2.3, < 1.3.0` |
| `1.2.x` | `>= 1.2.0, < 1.3.0` |
| `^1.2.3` | `>= 1.2.3, < 2.0.0` |
| `1.x.x` | `>= 1.0.0, < 2.0.0` |
| `1.2 - 1.4.5` | `>= 1.2.0, <= 1.4.5` |

The course references the Masterminds semver library:
<https://github.com/Masterminds/semver>.

For reproducible installs, prefer exact pins in production and commit
`Chart.lock`.

## Dependency commands

| Command | Behavior |
| --- | --- |
| `helm dependency update <chart>` | Resolve ranges, download charts into `charts/`, and write/update `Chart.lock` |
| `helm dependency build <chart>` | Rebuild `charts/` from `Chart.lock`; does not re-resolve ranges |
| `helm dependency list <chart>` | Show declared dependencies and whether they are present |

Typical workflow:

```bash
helm dependency update guestbook
helm dependency list guestbook
helm template demo guestbook
helm install demo guestbook
```

`helm dependency update` is not the same as `helm repo update`:

- `helm repo update` refreshes repository indexes.
- `helm dependency update` resolves and downloads a chart's dependencies.

### Chart.lock

`Chart.lock` records the exact resolved versions and digests. It is the
dependency equivalent of a lock file.

Commit it for reproducible builds. In CI, use:

```bash
helm dependency build guestbook
```

If `Chart.lock` and `Chart.yaml` disagree, `helm dependency build` fails
and asks you to run `helm dependency update`.

## Conditions and tags

Dependencies can be enabled or disabled without editing `Chart.yaml`.

### Conditions

`condition` points to a boolean value in `values.yaml`:

```yaml
# Chart.yaml
dependencies:
  - name: database
    version: 1.2.0
    repository: https://charts.example.com
    condition: database.enabled
```

```yaml
# values.yaml
database:
  enabled: false
```

Conditions can be a comma-separated list. The first existing path wins.

### Tags

`tags` groups dependencies:

```yaml
# Chart.yaml
dependencies:
  - name: frontend
    version: 1.2.0
    repository: https://charts.example.com
    tags:
      - web
  - name: backend
    version: 1.2.0
    repository: https://charts.example.com
    tags:
      - api
```

```yaml
# values.yaml
tags:
  web: true
  api: false
```

### How enabling works

- `helm dependency update` downloads **all** dependencies regardless of
  conditions/tags.
- `helm install` only installs dependencies whose conditions/tags resolve
  to enabled.
- `--set` overrides `values.yaml`.
- **Conditions override tags** when both apply to the same dependency.

Examples:

```bash
helm dependency update guestbook

helm install demo guestbook
helm install demo guestbook --set database.enabled=true
helm install demo guestbook --set tags.api=false
helm install demo guestbook --set tags.web=true,tags.api=false
```

## Passing values to subcharts

Subchart values are nested under the subchart name in the parent
`values.yaml`:

```yaml
# parent values.yaml
frontend:
  replicaCount: 2
  service:
    type: NodePort

backend:
  secret:
    mongodb_uri:
      username: admin
      password: password

database:
  enabled: true
```

These override the subchart's own defaults. The parent chart can also read
them if needed, but normally they are simply passed down.

### Global values

Values under `global` are available to the parent and all subcharts:

```yaml
# parent values.yaml
global:
  environment: dev
  imageRegistry: registry.example.com
```

```yaml
# any template
image: {{ .Values.global.imageRegistry }}/myapp:{{ .Chart.AppVersion }}
```

Use globals sparingly; they couple charts together.

### Exporting child values

A child chart can expose values to its parent with `exports`:

```yaml
# child values.yaml
exports:
  data:
    mongodb_uri:
      username: admin
      password: password
```

The parent imports the export in its `Chart.yaml`:

```yaml
dependencies:
  - name: backend
    version: ~1.2.1
    repository: https://charts.example.com
    import-values:
      - data
```

With the short form (`- data`), the exported block is merged at the
parent's top level. With the long form, map child to parent:

```yaml
dependencies:
  - name: backend
    version: ~1.2.1
    repository: https://charts.example.com
    import-values:
      - child: data
        parent: frontend_data
```

Then the parent can use:

```yaml
{{ .Values.frontend_data.mongodb_uri.username }}
```

## Reproducible dependency checklist

1. Pin versions or narrow ranges in `Chart.yaml`.
2. Run `helm dependency update` when changing dependencies.
3. Commit both `Chart.yaml` and `Chart.lock`.
4. Commit `charts/` only if your workflow requires vendoring.
5. In CI, run `helm dependency build` and then `helm lint`.
6. Package with an explicit version, for example
   `helm package guestbook --version 1.2.0`.

## Key takeaways

- `helm package` creates `name-version.tgz`; repositories need
  `index.yaml`.
- Dependencies are declared in `Chart.yaml` in Helm 3.
- `helm dependency update` resolves and downloads; `build` restores from
  `Chart.lock`.
- Conditions and tags control which dependencies install; conditions win.
- Use globals and `import-values` to share configuration between charts.
