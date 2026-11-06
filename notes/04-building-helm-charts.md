# 04 - Building Helm Charts

Source: `05/building-helm-charts-slides.pdf`

## Chart structure

A chart is a directory with a required metadata file and optional
directories and files:

```
mychart/
  Chart.yaml          # required: chart metadata
  values.yaml         # default configuration values
  values.schema.json  # optional: JSON schema for values validation
  charts/             # packaged or unpacked subcharts
  crds/               # CustomResourceDefinitions installed before templates
  templates/          # Kubernetes manifests and helpers
    _helpers.tpl      # named templates (not rendered as an object)
    NOTES.txt         # post-install/upgrade notes
    deployment.yaml
    service.yaml
    ...
  README.md
  .helmignore         # files to exclude when packaging
  LICENSE
```

Minimal chart:

```yaml
# Chart.yaml
apiVersion: v2
name: mychart
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"
```

```yaml
# values.yaml
replicaCount: 1
image:
  repository: nginx
  tag: "1.27"
service:
  type: ClusterIP
  port: 80
```

Generate a starting point:

```bash
helm create mychart
```

Inspect it before editing. `helm create` gives you a Deployment, Service,
Ingress, ServiceAccount, HPA, tests, and helper templates. It is a good
reference for conventions, but remove what you do not need.

## Chart.yaml

Important fields:

| Field | Meaning |
| --- | --- |
| `apiVersion` | Chart API version: `v2` for Helm 3+ |
| `name` | Chart name |
| `version` | Chart version, SemVer 2.0 |
| `appVersion` | Version of the application being packaged |
| `description` | Human-readable description |
| `type` | `application` or `library` |
| `kubeVersion` | Supported Kubernetes version range |
| `dependencies` | Charts this chart depends on |
| `maintainers` | Contact information |
| `keywords`, `home`, `sources`, `icon` | Discovery and metadata |

**Chart version is not application version.**

- `version` changes when the chart packaging/templates change.
- `appVersion` changes when the packaged application changes.

Both use semantic versioning conventions, but `version` must be SemVer and
drives repository resolution.

## Semantic versioning

`MAJOR.MINOR.PATCH`

- **MAJOR** - incompatible changes
- **MINOR** - backwards-compatible features
- **PATCH** - backwards-compatible fixes

Examples: `1.0.0`, `1.2.3`, `2.0.0-rc.1`.

Pre-release and build metadata are allowed: `1.2.3-beta.1+build.5`.

## Helm concepts revisited

| Concept | Definition |
| --- | --- |
| Chart | The package/definition |
| Release | An installed instance of a chart |
| Revision | One version of a release's history |
| Chart version | Version of the package |
| App version | Version of the software inside the package |

Example: `myapp` chart 1.2.0 can install application version 2.4.1. The
release `dev-myapp` can be at revision 3 after two upgrades.

## Core lifecycle commands

| Action | Command |
| --- | --- |
| Install a release | `helm install <release> <chart>` |
| Upgrade a release | `helm upgrade <release> <chart>` |
| Install or upgrade | `helm upgrade --install <release> <chart>` |
| Roll back | `helm rollback <release> <revision>` |
| Print history | `helm history <release>` |
| Show status | `helm status <release>` |
| Show all details | `helm get all <release>` |
| Uninstall | `helm uninstall <release>` |
| List releases | `helm list` |
| Render locally | `helm template <release> <chart>` |
| Dry run against cluster | `helm install --dry-run --debug <release> <chart>` |

## Release lifecycle in practice

```bash
helm install demo ./mychart -n demo --create-namespace
helm list -n demo
helm status demo -n demo
helm history demo -n demo

helm upgrade demo ./mychart -n demo --set replicaCount=3
helm history demo -n demo

helm rollback demo 1 -n demo
helm history demo -n demo

helm uninstall demo -n demo
```

Notes:

- `helm upgrade` creates a new revision only if the rendered release
  changes (or `--force` is used).
- `helm rollback` itself creates a new revision that represents the
  restored state.
- `helm uninstall --keep-history` removes live resources but keeps release
  history so you can inspect or roll back later. In Helm 2 this was
  `helm delete --purge` versus `helm delete`.

## Helm 2 versus Helm 3 command changes

| Helm 2 | Helm 3 |
| --- | --- |
| `helm install --name release chart` | `helm install release chart` |
| `helm install chart` | `helm install --generate-name chart` |
| `helm delete --purge release` | `helm uninstall release` |
| `helm delete release` | `helm uninstall --keep-history release` |
| `helm get release` | `helm get all release` |

## Umbrella charts

An **umbrella chart** (parent chart) packages multiple subcharts so a
whole application can be installed as one release.

```
guestbook/
  Chart.yaml
  values.yaml
  charts/
    frontend/
    backend/
    database/
```

The parent chart usually contains little or no application logic itself.
It wires subcharts together through values and dependencies. Subcharts are
rendered with the release name and namespace of the parent release.

Two ways to add a subchart:

```bash
# Local directory copied under charts/
cp -r frontend guestbook/charts/

# Declared dependency resolved from a repository or local path
helm dependency update guestbook
```

## Version 1 to version 2 upgrade path

The course evolves Guestbook:

1. **v1** - one frontend Pod, Service, Ingress.
2. **v2** - frontend, backend API, and database, each with its own
   objects.

The Helm progression is:

1. Raw `kubectl` manifests -> `lab1`, `lab2`
2. Single chart -> `lab5`
3. Umbrella chart -> `lab6`
4. Values and template logic -> `lab7`, `lab8`, `lab9`
5. Dependencies and repositories -> `lab10`, `lab11`

## Best practices

- Keep one resource kind per template file when practical.
- Put shared naming logic in `templates/_helpers.tpl`.
- Do not hard-code names; use `.Release.Name`, `.Chart.Name`, or helpers.
- Add labels consistently (`app.kubernetes.io/name`,
  `app.kubernetes.io/instance`, `helm.sh/chart`).
- Keep `values.yaml` documented and free of secrets.
- Store secrets in external secret managers or Kubernetes Secrets, not in
  committed values files.
- Run `helm lint`, `helm template`, and `helm install --dry-run` before
  installing.

## Key takeaways

- `Chart.yaml` is the package metadata; `version` and `appVersion` differ.
- A release is an instance; revisions track its history.
- Umbrella charts aggregate subcharts.
- Use `helm template` and `--dry-run --debug` to validate rendering.
