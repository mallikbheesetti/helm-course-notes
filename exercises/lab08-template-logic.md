# Lab 08 - Template Logic

## Goal

Add real templating logic to the Guestbook chart: functions, pipelines,
`with`, conditions, loops, variables, named templates, whitespace control,
and `NOTES.txt`.

## Prerequisites

- Lab 07 chart with values

## Tasks

1. **Functions and pipelines**

   Add labels that use defaults, truncation, and quoting:

   ```yaml
   app.kubernetes.io/name: {{ .Values.frontend.image.repository | default .Chart.Name | trunc 63 | trimSuffix "-" }}
   app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
   ```

   Add a Secret value encoded with `b64enc`:

   ```yaml
   data:
     password: {{ .Values.backend.password | b64enc | quote }}
   ```

2. **Conditional resources**

   Guard the Ingress and the database with values:

   ```gotemplate
   {{- if .Values.frontend.ingress.enabled }}
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   ...
   {{- end }}
   ```

   ```gotemplate
   {{- if .Values.database.enabled }}
   apiVersion: v1
   kind: Service
   ...
   {{- end }}
   ```

3. **Loops**

   Support multiple ingress hosts from values:

   ```yaml
   ingress:
     enabled: true
     hosts:
       - host: frontend.minikube.local
         service: frontend
         port: 80
       - host: backend.minikube.local
         service: backend
         port: 80
   ```

   Render them with `range`.

4. **Variables and root context**

   Use `$` inside nested ranges. Capture the outer host with a variable so
   the inner path loop can still use it.

5. **Scope with `with`**

   Simplify a block:

   ```gotemplate
   {{- with .Values.frontend.service }}
   type: {{ .type }}
   port: {{ .port }}
   {{- end }}
   ```

6. **Named templates**

   Move repeated labels into `_helpers.tpl`:

   ```gotemplate
   {{- define "guestbook.labels" -}}
   app.kubernetes.io/name: {{ .Chart.Name }}
   app.kubernetes.io/instance: {{ .Release.Name }}
   app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
   {{- end -}}
   ```

   Use `include` with `nindent`:

   ```yaml
   metadata:
     labels:
       {{- include "guestbook.labels" . | nindent 4 }}
   ```

7. **Whitespace**

   Ensure rendered YAML has no stray blank lines or broken indentation.
   Use `{{-`, `-}}`, `indent`, and `nindent`.

8. **NOTES.txt**

   Print the access URL conditionally:

   ```gotemplate
   {{- if .Values.frontend.ingress.enabled }}
   Open: http://{{ .Release.Name }}.{{ .Values.frontend.ingress.host }}
   {{- else }}
   Run: kubectl port-forward svc/{{ .Release.Name }}-frontend 8080:80
   {{- end }}
   ```

9. **Validate**

   ```bash
   helm lint ./guestbook
   helm template demo ./guestbook
   helm template demo ./guestbook --set frontend.ingress.enabled=false
   helm template demo ./guestbook --set database.enabled=false
   helm install demo ./guestbook -n lab08 --create-namespace --dry-run --debug
   ```

## Hints

- `default` takes the default first: `value | default "fallback"`.
- Logical operators are functions: `eq`, `ne`, `gt`, `lt`, `and`, `or`,
  `not`, `empty`.
- Use `$` to reach the root context inside `range`/`with`.
- `template` cannot be piped; `include` returns a string and can be piped.
- `nindent` adds a newline before the indentation, which is usually what
  you want after a key.

## Verify

```bash
helm template demo ./guestbook | grep -E 'kind:|app.kubernetes.io'
helm template demo ./guestbook --set frontend.ingress.enabled=false | grep -c 'kind: Ingress'
helm template demo ./guestbook --set database.enabled=false | grep -c 'mongo'
helm template demo ./guestbook --debug 2>&1 | head -80
```

Expected:

- Disabling the Ingress removes the Ingress object.
- Disabling the database removes its resources.
- Labels are consistent and valid.
- Rendered YAML parses with `kubectl apply --dry-run=client -f -`.

## Solution sketch

```gotemplate
{{/* templates/ingress.yaml */}}
{{- if .Values.frontend.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-guestbook
  labels:
    {{- include "guestbook.labels" . | nindent 4 }}
spec:
  rules:
  {{- range $host := .Values.frontend.ingress.hosts }}
    - host: {{ $host.host | quote }}
      http:
        paths:
        {{- range $host.paths }}
          - path: {{ .path }}
            pathType: Prefix
            backend:
              service:
                name: {{ $.Release.Name }}-{{ $host.service }}
                port:
                  number: {{ $host.port }}
        {{- end }}
  {{- end }}
{{- end }}
```

```yaml
# values.yaml
frontend:
  ingress:
    enabled: true
    hosts:
      - host: frontend.minikube.local
        service: frontend
        port: 80
        paths:
          - path: /
      - host: backend.minikube.local
        service: backend
        port: 80
        paths:
          - path: /
```

## Stretch

- Add a helper that renders annotations from a map with `toYaml`.
- Add an `if/else if` chain for service type.
- Use `randAlphaNum` to generate a password and store it in a Secret
  (note: this changes on every render unless you use `lookup`).
- Use `.Files.Get` to inject a config file from the chart.

## Cleanup

```bash
helm uninstall demo -n lab08
kubectl delete namespace lab08
```

## Reflection

When should logic live in a helper template rather than in each resource
file? What are the risks of generating random values during a template
render?
