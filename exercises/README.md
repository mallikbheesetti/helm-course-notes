# Practice Labs

Eleven exercises that follow the course progression. Each lab is
self-contained and includes a goal, tasks, hints, verification, cleanup,
and a solution sketch.

## Before you start

```bash
mkdir -p ~/helm-labs
cd ~/helm-labs
helm version
kubectl get nodes
```

Recommended habits:

- Use one namespace per lab.
- Render before installing: `helm template` and `--dry-run --debug`.
- Read `NOTES.txt` output after installing.
- Clean up when done.

## Lab index

| Lab | File | Focus | Reference |
| --- | --- | --- | --- |
| 01 | [lab01-kubectl-v1.md](lab01-kubectl-v1.md) | Raw Kubernetes: Pod, Service, Ingress | [raw/lab01](../labs/raw/lab01/README.md) |
| 02 | [lab02-kubectl-v2.md](lab02-kubectl-v2.md) | Raw Kubernetes: three-tier app with Secret and PVC | [raw/lab02](../labs/raw/lab02/README.md) |
| 03 | [lab03-install-helm.md](lab03-install-helm.md) | minikube, kubectl, Helm, local hostnames | [setup/lab03](../labs/setup/lab03/README.md) |
| 04 | [lab04-release-lifecycle.md](lab04-release-lifecycle.md) | Install, upgrade, history, rollback, uninstall | [setup/lab04](../labs/setup/lab04/README.md) |
| 05 | [lab05-first-chart.md](lab05-first-chart.md) | Convert manifests into a chart | [reference/lab05](../labs/reference/lab05/guestbook) |
| 06 | [lab06-umbrella-chart.md](lab06-umbrella-chart.md) | Parent chart with subcharts | [reference/lab06](../labs/reference/lab06/guestbook) |
| 07 | [lab07-values.md](lab07-values.md) | Parameterize and override values | [reference/lab07](../labs/reference/lab07/guestbook) |
| 08 | [lab08-template-logic.md](lab08-template-logic.md) | Functions, conditions, loops, helpers | [reference/lab08](../labs/reference/lab08/guestbook) |
| 09 | [lab09-dev-test-releases.md](lab09-dev-test-releases.md) | Multiple releases from one chart | [reference/lab09](../labs/reference/lab09/guestbook) |
| 10 | [lab10-dependencies.md](lab10-dependencies.md) | Package, publish, dependency resolution | [reference/lab10](../labs/reference/lab10/guestbook) |
| 11 | [lab11-existing-charts.md](lab11-existing-charts.md) | Consume and customize third-party charts | [reference/lab11](../labs/reference/lab11/guestbook) |

The reference material is collected under [`labs/`](../labs/README.md), with
notes on how the adapted charts differ from the upstream course snapshots.

## Suggested schedule

- **Session 1:** Labs 01-03 (environment and raw Kubernetes)
- **Session 2:** Labs 04-06 (Helm basics and chart structure)
- **Session 3:** Labs 07-09 (values and templating)
- **Session 4:** Labs 10-11 (dependencies, repositories, existing charts)

## Grading yourself

For each lab, you are done when:

1. The verification commands produce the expected result.
2. `helm lint` and `helm template` pass for any chart you write.
3. You can explain why each resource exists.
4. The cleanup commands remove the release and namespace.
