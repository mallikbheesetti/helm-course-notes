# Troubleshooting Helm Installs

This guide covers common errors encountered while working through the
course labs, including errors seen with the sample Guestbook chart on
modern Kubernetes clusters.

## First: separate Helm from Kubernetes from the cluster

When an install fails, decide which layer is broken:

```bash
helm version
kubectl config current-context
kubectl cluster-info
kubectl get nodes
helm list -A
```

If `kubectl` cannot reach the API server, fix the cluster before changing
the chart.

## `no matches for kind "Ingress" in version "extensions/v1beta"`

Full error:

```
unable to build kubernetes objects from release manifest:
resource mapping not found for name: "...-ingress" ...
no matches for kind "Ingress" in version "extensions/v1beta"
ensure CRDs are installed first
```

Cause: `extensions/v1beta1` Ingress was removed from Kubernetes. Modern
clusters only serve `networking.k8s.io/v1` Ingress.

Modern template:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
spec:
  rules:
    - host: example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Release.Name }}-frontend
                port:
                  number: 80
```

Key changes from the old API:

| Old (`extensions/v1beta1`) | New (`networking.k8s.io/v1`) |
| --- | --- |
| `serviceName` | `backend.service.name` |
| `servicePort` | `backend.service.port.number` (or `.name`) |
| No `pathType` | `pathType` is required (`Prefix`, `Exact`, `ImplementationSpecific`) |
| `networking.k8s.io/v1beta1` | `networking.k8s.io/v1` |

Check what the cluster serves:

```bash
kubectl api-resources | grep -i ingress
kubectl explain ingress.spec.rules.http.paths
```

## Admission webhook: `connection refused`

Full error:

```
server-side apply failed for object ... Kind=Ingress:
Internal error occurred: failed calling webhook
"validate.nginx.ingress.kubernetes.io":
failed to call webhook: Post "https://ingress-nginx-controller-admission.ingress-nginx.svc:443/...":
dial tcp 10.x.x.x:443: connect: connection refused
```

Cause: the `ingress-nginx` validating admission webhook is registered, but
the controller behind it is not reachable. Helm's apply is intercepted by
the webhook before the object is stored, so a cluster-side webhook
failure blocks the install. The chart itself may be perfectly valid.

Check:

```bash
kubectl -n ingress-nginx get pods,svc,endpoints
kubectl -n ingress-nginx get endpointslices
kubectl get validatingwebhookconfigurations | grep ingress
```

Common reasons:

- ingress-nginx controller is not installed in this cluster.
- Controller pods are not Ready or are CrashLooping.
- The controller was scaled to zero or removed.
- A stale `ValidatingWebhookConfiguration` remains after uninstalling
  ingress-nginx.
- Service has no endpoints because no Ready pod matches its selector.

This is not fixed by editing the chart. Fix or remove the webhook
controller, or install the Ingress controller the chart expects.

## `TLS handshake timeout` from kubectl

```
Unable to connect to the server: net/http: TLS handshake timeout
```

Cause: the Kubernetes API server (or the path to it) is not responding.
On minikube this often means the VM/container is stopped, unhealthy, or
resource-starved.

```bash
minikube status
minikube logs
kubectl cluster-info
```

Restart or recreate the cluster if needed. Do not debug Helm until
`kubectl get nodes` works reliably.

## `release: already exists`

Cause: a release with that name already exists in the namespace. Release
names are namespaced but must be unique within a namespace.

```bash
helm list -n <namespace>
helm list -A
```

Options:

```bash
helm uninstall <release> -n <namespace>
helm upgrade --install <release> <chart> -n <namespace>
# or choose another release name
```

## `chart requires kubeVersion ... which is incompatible`

The chart declares a `kubeVersion` constraint that your cluster does not
satisfy.

```bash
kubectl version
helm show chart <chart>
```

Use a compatible chart version or a compatible cluster. Do not remove the
constraint just to silence the error unless you understand the
consequences.

## `found in Chart.yaml, but missing in charts/ directory`

Cause: dependencies are declared but not downloaded.

```bash
helm dependency update <chart>
# or, with a committed Chart.lock:
helm dependency build <chart>
```

After updating, `helm dependency list <chart>` should show all
dependencies with status `ok`.

## `Chart.lock is out of sync with Chart.yaml`

Cause: `Chart.yaml` changed after `Chart.lock` was written.

```bash
helm dependency update <chart>
```

Then commit the updated lock file.

## `values don't meet the specifications of the schema(s)`

Cause: `values.schema.json` rejected the provided values, or a value has
the wrong type.

```bash
helm install demo <chart> --dry-run --debug
helm show values <chart>
helm show chart <chart>
```

Watch for `--set` type coercion. Use `--set-string` when the target must
remain a string:

```bash
helm install demo <chart> --set-string image.tag=1.10
```

Common traps:

- `true`/`false` become booleans, not strings.
- `yes`/`no`/`on`/`off` can be interpreted by YAML as booleans.
- Ports set with `--set` become numbers; quote them only if the schema
  expects a string.

## Rendered YAML looks broken

Cause: template whitespace, wrong indentation, or a value rendered as a
map where a scalar was expected.

```bash
helm template demo <chart> --debug
helm install demo <chart> --dry-run --debug 2>&1 | less
```

Use:

- `{{-` and `-}}` to trim action whitespace
- `indent` / `nindent` for blocks
- `toYaml` for maps and lists
- `quote` for strings that YAML might reinterpret
- `helm lint <chart>`

If an object is missing entirely, check the guarding `if` condition:

```bash
helm template demo <chart> --set ingress.enabled=true
```

## `nil pointer evaluating interface`

Cause: a value path does not exist, often inside a subchart or when
upgrading a release with old values.

Fix the template to guard the path:

```yaml
{{- with .Values.optional }}
value: {{ .something }}
{{- end }}
```

or use `default` / `hasKey`:

```yaml
value: {{ .Values.optional.something | default "fallback" }}
```

Also inspect the actual values:

```bash
helm get values <release> -n <namespace>
```

## Upgrade fails on immutable fields

Cause: a field such as a Deployment selector, Service `clusterIP`, or
StatefulSet volume claim template cannot be changed in place.

Options:

- Revert the change.
- Delete and recreate the resource (with data-loss awareness).
- Use `helm upgrade --force` only when you understand the recreation
  impact.

## Resources are stuck terminating

```bash
kubectl get all -n <namespace>
kubectl get finalizers -n <namespace>
```

Check for finalizers, PVC protection, or a controller that is down.
`helm uninstall` can only remove what the API server accepts.

## Pods fail after a successful Helm install

Helm successfully applied the manifests; the application is now failing.
Switch to Kubernetes debugging:

```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Check:

- Image pull errors
- CrashLoopBackOff
- Missing ConfigMap/Secret
- PVC pending
- Service selector mismatch
- Readiness/Liveness probe failures
- Ingress controller missing

## Ingress host not reachable

```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <name> -n <namespace>
kubectl get svc -n ingress-nginx
minikube tunnel
```

Check that:

- The Ingress has an address.
- The host in the Ingress matches the host in the request.
- `/etc/hosts` points the host to `127.0.0.1`.
- `minikube tunnel` is running.
- The backend Service name and port match the actual Service.
- The Ingress controller is installed.

## Release state exists but objects are gone

```bash
helm list -A
helm history <release> -n <namespace>
helm get manifest <release> -n <namespace>
```

If objects were deleted manually, re-apply with an upgrade or reinstall.
If release metadata is stale, uninstall and reinstall. Use
`--keep-history` only when you want to retain history intentionally.

## How to reset a lab cleanly

```bash
helm uninstall <release> -n <namespace>
kubectl delete namespace <namespace>
helm list -A
```

Do not delete Helm's storage Secrets manually unless you are deliberately
repairing a broken release. Prefer Helm commands, and know that Helm 3
stores release state as Secrets in the release namespace.
