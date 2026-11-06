# Course Labs and Reference Charts

This directory brings the hands-on lab material into this repository and
connects it to the notes and exercises.

The source material is the Pluralsight course
"Packaging Applications with Helm for Kubernetes" (Helm 3), originally
published at `https://github.com/phcollignon/helm3`.

## Layout

| Path | Contents |
| --- | --- |
| `raw/lab01/` | Guestbook v1 Kubernetes manifests (Pod/Service/Ingress) |
| `raw/lab02/` | Guestbook v2 Kubernetes manifests (ConfigMap, Secret, PV/PVC, three tiers) |
| `setup/lab03/` | Local minikube and kubectl setup instructions |
| `setup/lab04/` | Helm installation, repository setup, and cleanup demo |
| `reference/lab05/` | First chart: frontend only |
| `reference/lab06/` | Umbrella chart: frontend, backend, database subcharts |
| `reference/lab07/` | Values-driven umbrella chart |
| `reference/lab08/` | Template logic and helpers |
| `reference/lab09/` | Dev/test releases from one chart |
| `reference/lab10/` | Declared dependencies, conditions, and tags |
| `reference/lab11/` | Repository-oriented chart with vendored packaged subcharts |

The application source code is not copied here. The manifests and charts
use the course's prebuilt images (`phico/frontend`, `phico/backend`, and
the official `mongo` image), so you only need a cluster and Helm.

## Mapping to the exercises

| Exercise | Raw lab | Reference chart |
| --- | --- | --- |
| [Lab 01](../exercises/lab01-kubectl-v1.md) | `raw/lab01` | n/a |
| [Lab 02](../exercises/lab02-kubectl-v2.md) | `raw/lab02` | n/a |
| [Lab 03](../exercises/lab03-install-helm.md) | `setup/lab03` | n/a |
| [Lab 04](../exercises/lab04-release-lifecycle.md) | `setup/lab04` | n/a |
| [Lab 05](../exercises/lab05-first-chart.md) | `lab5_*` upstream | `reference/lab05/guestbook` |
| [Lab 06](../exercises/lab06-umbrella-chart.md) | `lab6_*` upstream | `reference/lab06/guestbook` |
| [Lab 07](../exercises/lab07-values.md) | `lab7_*` upstream | `reference/lab07/guestbook` |
| [Lab 08](../exercises/lab08-template-logic.md) | `lab8_*` upstream | `reference/lab08/guestbook` |
| [Lab 09](../exercises/lab09-dev-test-releases.md) | `lab9_*` upstream | `reference/lab09/guestbook` |
| [Lab 10](../exercises/lab10-dependencies.md) | `lab10_*` upstream | `reference/lab10/guestbook` |
| [Lab 11](../exercises/lab11-existing-charts.md) | `lab11_*` upstream | `reference/lab11/guestbook` |

## Using a reference chart

```bash
cd labs/reference/lab09
helm lint ./guestbook
helm template demo ./guestbook
helm install demo ./guestbook -n lab09 --create-namespace
helm list -n lab09
helm uninstall demo -n lab09
kubectl delete namespace lab09
```

Try the values exercises against the reference charts:

```bash
helm template demo ./guestbook --set frontend.replicaCount=2
helm template demo ./guestbook --set database.enabled=false
helm template demo ./guestbook --set tags.api=false
```

## Changes from the upstream lab snapshots

The reference charts are adapted, not verbatim copies, so they lint and
render cleanly with current Helm:

- Ingress resources use `networking.k8s.io/v1` with `pathType`.
- Parent `Chart.yaml` files declare their `charts/` subcharts as
  dependencies, so `helm lint` passes.
- Lab 05 uses values and release-aware names instead of hard-coded names.
- Lab 05's Ingress only routes to the frontend, matching the v1 app.
- Lab 08 and later build the MongoDB URI from values with the correct
  `dbport` key instead of leaving the port empty.
- Lab 10 uses local `file://` dependencies and unpacked subcharts, so it
  works offline; the upstream `http://localhost:8080` repository URL is
  not required.
- Lab 11 removes an unused `database` archive so the declared dependencies
  match `charts/`, and drops the stale `Chart.lock` that pointed at
  `http://localhost:8080`. Its `Chart.yaml` keeps the course's local
  repository URLs, but the packaged subcharts are vendored under `charts/`,
  so linting and rendering work without that repository. Do not run
  `helm dependency update` for Lab 11 unless you recreate the local repo.

The original upstream lab directories (`helm3/lab5_*` through
`helm3/lab11_*`) can be compared side by side if you have a local copy of
the course repository.

## Validation

Run the repository validation script:

```bash
./scripts/validate.sh
```

It lints and templates every reference chart. The raw Kubernetes
manifests are intended for a live lab cluster.
