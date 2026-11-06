# Lab 05 - Your First Chart

> Reference implementation: [`labs/reference/lab05/guestbook`](../labs/reference/lab05/guestbook)

## Goal

Convert the raw Guestbook v1 manifests from Lab 01 into a reusable Helm
chart with parameterized names, images, and ports.

## Prerequisites

- Lab 01 manifests or a working frontend example
- Helm 3+

## Tasks

1. Create a chart directory:

   ```bash
   cd ~/helm-labs
   mkdir -p guestbook/templates
   ```

2. Write `Chart.yaml` with `apiVersion: v2`, name `guestbook`, version
   `0.1.0`, and a meaningful `appVersion`.

3. Write `values.yaml` with at least:

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
   ```

4. Create templates:

   - `templates/frontend-pod.yaml` (or a Deployment)
   - `templates/frontend-service.yaml`
   - `templates/frontend-ingress.yaml`
   - `templates/_helpers.tpl`
   - `templates/NOTES.txt`

5. Use release-aware names, for example:

   ```yaml
   metadata:
     name: {{ .Release.Name }}-frontend
   ```

6. Guard the Ingress with `{{- if .Values.frontend.ingress.enabled }}`.

7. Add a helper for labels:

   ```gotemplate
   {{- define "guestbook.labels" -}}
   app.kubernetes.io/name: {{ .Chart.Name }}
   app.kubernetes.io/instance: {{ .Release.Name }}
   helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
   {{- end -}}
   ```

8. Validate and install:

   ```bash
   helm lint ./guestbook
   helm template demo ./guestbook
   helm install demo ./guestbook -n lab05 --create-namespace
   helm status demo -n lab05
   ```

9. Verify the rendered names differ by release:

   ```bash
   helm template dev ./guestbook | grep 'name:'
   helm template test ./guestbook | grep 'name:'
   ```

## Hints

- Do not hard-code `demo` anywhere; use `.Release.Name`.
- Chart name comes from `Chart.yaml` as `.Chart.Name`.
- Ingress requires `networking.k8s.io/v1` and `pathType`.
- `NOTES.txt` is not applied to the cluster; it is printed after install.
- `_helpers.tpl` is not rendered as an object because the filename starts
  with `_`.

## Verify

```bash
helm lint ./guestbook
helm template demo ./guestbook
helm install demo ./guestbook -n lab05 --create-namespace
kubectl -n lab05 get pod,svc,ingress
```

Expected:

- `helm lint` reports no failures.
- Rendered manifests contain `demo-frontend`.
- Pod is Running and Service endpoints are populated.
- Ingress points at `demo-frontend` Service.

## Solution sketch

```yaml
# Chart.yaml
apiVersion: v2
name: guestbook
description: Guestbook frontend
type: application
version: 0.1.0
appVersion: "1.0"
```

```yaml
# templates/frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-frontend
  labels:
    {{- include "guestbook.labels" . | nindent 4 }}
spec:
  selector:
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: 80
```

```yaml
# templates/frontend-ingress.yaml
{{- if .Values.frontend.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-frontend
spec:
  rules:
    - host: {{ .Release.Name }}.{{ .Values.frontend.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Release.Name }}-frontend
                port:
                  number: {{ .Values.frontend.service.port }}
{{- end }}
```

## Stretch

- Add `values.schema.json` to validate required values.
- Add a test hook using `templates/tests/`.
- Convert the Pod to a Deployment and add a replica count.
- Add `helm.sh/resource-policy: keep` to a resource and observe uninstall.

## Cleanup

```bash
helm uninstall demo -n lab05
kubectl delete namespace lab05
```

## Reflection

What makes this chart reusable across environments? Which values would you
expect to change between dev and production?
