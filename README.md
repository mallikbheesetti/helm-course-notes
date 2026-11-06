# Helm Notes and Practice Labs

Study notes and hands-on exercises distilled from the
`kubernetes-packaging-applications-helm` course material in
`helm-notes/` (sections 02 through 08).

The source is a Helm 3 course. Commands here work with Helm 3 and are
compatible with Helm 4 unless noted. Always check your version with
`helm version`.

## What is in this repository

| Path | Contents |
| --- | --- |
| `notes/` | Ordered study notes, one file per course section plus a cheatsheet and troubleshooting guide |
| `exercises/` | Eleven labs that build from raw `kubectl` manifests to dependencies and third-party charts |
| `starters/helm-chart-skeleton/` | Minimal chart skeleton to copy when starting a lab |
| `sources/` | Extracted text from the original slide decks, kept for reference |

## Learning path

1. **Foundations** - `notes/01-course-introduction.md`, `notes/02-discovering-helm.md`
2. **Environment** - `notes/03-install-kubernetes-and-helm.md`, Lab 03
3. **Packaging** - `notes/04-building-helm-charts.md`, Labs 01, 02, 04, 05, 06
4. **Templating** - `notes/05-customizing-templates.md`, Labs 07, 08, 09
5. **Dependencies and reuse** - `notes/06-managing-dependencies.md`, `notes/07-using-existing-charts.md`, Labs 10, 11

## Labs at a glance

| Lab | Topic | Main skill |
| --- | --- | --- |
| 01 | Guestbook v1 with `kubectl` | Pod, Service, Ingress |
| 02 | Guestbook v2 with `kubectl` | ConfigMap, Secret, PVC, multiple tiers |
| 03 | Install the tooling | minikube, kubectl, Helm, local DNS |
| 04 | Release lifecycle | install, upgrade, rollback, history, uninstall |
| 05 | First chart | convert manifests into a chart |
| 06 | Umbrella chart | parent chart with subcharts |
| 07 | Values | parameterize and override values |
| 08 | Template logic | functions, flow control, loops, helpers |
| 09 | Multiple environments | dev and test releases from one chart |
| 10 | Dependencies | package, repository, dependency update, conditions and tags |
| 11 | Existing charts | search, inspect, install, customize third-party charts |

## Conventions used in the labs

- Work in a scratch directory such as `~/helm-labs`.
- Use a dedicated namespace per lab, for example `lab05`.
- Replace `dev` with your own release name when experimenting.
- Use `helm template` and `helm install --dry-run --debug` before applying.
- Clean up with `helm uninstall <release> -n <namespace>` and
  `kubectl delete namespace <namespace>`.

## Prerequisites

- Docker (or another minikube driver)
- `minikube`, `kubectl`, and `helm`
- A shell with network access to a Helm chart repository (Bitnami is used
  in Labs 10 and 11)

## Source material

Original slides and archive:

- `kubernetes-packaging-applications-helm.zip`
- `02/course-introduction-slides.pdf`
- `03/discovering-helm-slides.pdf`
- `04/installing-a-local-kubernetes-cluster-with-helm-slides.pdf`
- `05/building-helm-charts-slides.pdf`
- `06/customizing-charts-with-helm-templates-slides.pdf`
- `07/managing-dependencies-slides.pdf`
- `08/using-existing-helm-chart-slides.pdf`

Course lab repository referenced throughout the slides:
`https://github.com/phcollignon/helm3`

The PDFs are not copied into this repository; the extracted text lives in
`sources/extracted/` so the notes can be traced back to the slides.
