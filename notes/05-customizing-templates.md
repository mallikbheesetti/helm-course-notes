# 05 - Customizing Charts with Helm Templates

Source: `06/customizing-charts-with-helm-templates-slides.pdf`

## Why templates

A chart without templates is just a fixed set of manifests. Templates let
the same chart produce different Kubernetes objects for different
releases, namespaces, and environments.

Example: the same Service template produces:

```yaml
# release "dev"
metadata:
  name: dev-frontend
```

```yaml
# release "test"
metadata:
  name: test-frontend
```

Without templates you would copy and edit the YAML for every environment.

## The template engine

Helm uses Go's `text/template` package plus the **Sprig** function library.
Helm adds a few functions of its own (for example `include` and
`toYaml` integration).

```
Template + values.yaml + built-in objects
                 |
                 v
          Helm template engine
                 |
                 v
        Kubernetes manifests
```

Analogy:

| Technology | Directive |
| --- | --- |
| Bash | `${ENV_VAR}` |
| Windows batch | `%ENV_VAR%` |
| PHP | `<?php echo $title ?>` |
| JSP/ASP/EJS | `<%= title %>` |
| Velocity | `$var` |
| Yeoman | `<%= var %>` |
| **Go templates** | `{{ var }}` |

Simple example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name }}
spec:
  type: NodePort
  ports:
    - port: {{ .Values.port }}
```

With `values.yaml`:

```yaml
name: myservice
port: 80
```

The rendered manifest has `name: myservice` and `port: 80`.

## Values sources and precedence

Values can come from several places. Highest precedence wins:

1. `--set` / `--set-string` / `--set-file` on the command line
2. `-f` / `--values` files, later files override earlier files
3. The chart's `values.yaml`
4. Subchart defaults, with parent values overriding child values
5. Helm's built-in values (lowest)

Examples:

```bash
helm install demo ./mychart -f values-dev.yaml
helm install demo ./mychart -f values.yaml -f values-prod.yaml
helm install demo ./mychart --set service.type=NodePort
helm install demo ./mychart --set service.port=8080
```

Values files are merged, not replaced. Nested maps merge; scalar values
replace.

### Setting list items

```bash
# values.yaml: service.labels: [{name: name1}, {name: name2}]
helm install demo ./mychart --set service.labels[0].name=foo
```

### Typed `--set` variants

| Flag | Purpose |
| --- | --- |
| `--set` | Parse value types (booleans, numbers, null) |
| `--set-string` | Force string |
| `--set-file` | Read value from a file |

### Validating values with a schema

`values.schema.json` uses JSON Schema to validate values before rendering:

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "service": {
      "type": "object",
      "properties": {
        "type": { "type": "string", "enum": ["ClusterIP", "NodePort", "LoadBalancer"] },
        "port": { "type": "integer", "minimum": 1, "maximum": 65535 }
      },
      "required": ["type", "port"]
    }
  }
}
```

Validation runs for `helm template`, `helm install`, and `helm upgrade`.

## Built-in objects

| Object | Examples | Meaning |
| --- | --- | --- |
| `.Release` | `.Release.Name`, `.Release.Namespace`, `.Release.Revision`, `.Release.Service`, `.Release.IsInstall`, `.Release.IsUpgrade` | Release metadata |
| `.Chart` | `.Chart.Name`, `.Chart.Version`, `.Chart.AppVersion`, `.Chart.Description` | Chart metadata from `Chart.yaml` |
| `.Capabilities` | `.Capabilities.KubeVersion`, `.Capabilities.KubeVersion.Major/Minor`, `.Capabilities.APIVersions` | Cluster capabilities |
| `.Template` | `.Template.Name`, `.Template.BasePath` | Current template metadata |
| `.Files` | `.Files.Get "conf.ini"`, `.Files.Glob`, `.Files.AsConfig` | Non-template files in the chart |

Example:

```yaml
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
```

## Functions and pipelines

Go templates call functions in prefix form. Pipelines pass the result of
one function as the last argument to the next.

| Function | Pipeline form |
| --- | --- |
| `quote value` | `value \| quote` |
| `default defaultValue value` | `value \| default defaultValue` |
| `upper value` | `value \| upper` |
| `trunc 63 value` | `value \| trunc 63` |
| `trimSuffix "-" value` | `value \| trimSuffix "-"` |
| `b64enc value` | `value \| b64enc` |
| `randAlphaNum 10` | `randAlphaNum 10` |
| `toYaml value` | `value \| toYaml` |
| `printf "format" args` | `printf "%s-%s" .Release.Name .Chart.Name` |
| `join "-" list` | `list ... \| join "-"` |

Examples:

```yaml
metadata:
  name: {{ .Values.service.name | default .Chart.Name }}
```

```yaml
metadata:
  labels:
    app.kubernetes.io/name: {{ .Values.service.name | trunc 63 | trimSuffix "-" }}
```

```yaml
data:
  mongodb-root-password: {{ .Values.mongodbRootPassword | b64enc | quote }}
```

Function sources:

- Go `text/template`: <https://pkg.go.dev/text/template>
- Sprig: <https://masterminds.github.io/sprig/>
- Helm template functions: <https://helm.sh/docs/chart_template_guide/function_list/>

Custom Go functions are not supported. Put reusable logic in named
templates instead.

## Changing scope with `with`

`with` changes `.` to a sub-object, reducing repetition:

```yaml
spec:
  {{- with .Values.service }}
  type: {{ .type }}
  ports:
    - port: {{ .port }}
      targetPort: 80
  {{- end }}
```

Inside `with`, `.` is `.Values.service`. Use `$` to reach the root context:

```yaml
{{- with .Values.service }}
name: {{ $.Release.Name }}
{{- end }}
```

## Whitespace control

Template actions leave newlines and spaces. Trim them with hyphens:

- `{{-` trims whitespace before the action
- `-}}` trims whitespace after the action

```yaml
spec:
  {{- with .Values.service }}
  type: {{ .type }}
  ports:
    - port: {{ .port }}
      targetPort: 80
  {{- end }}
```

Use `indent` or `nindent` when including multi-line blocks:

```yaml
  annotations:
{{ include "mychart.annotations" . | indent 4 }}
```

`nindent` adds a leading newline plus indentation:

```yaml
  annotations:
    {{- toYaml .Values.annotations | nindent 4 }}
```

## Logical operators

In Go templates, operators are functions:

| Operator | Function | Example |
| --- | --- | --- |
| Equal | `eq` | `eq .Val1 .Val2` |
| Not equal | `ne` | `ne .Val1 .Val2` |
| Greater than | `gt` | `gt .Val1 .Val2` |
| Less than | `lt` | `lt .Val1 .Val2` |
| Or | `or` | `or .Val1 .Val2` |
| And | `and` | `and .Val1 .Val2` |
| Not | `not` | `not .Val1` |
| Empty | `empty` | `empty .Val1` |

Examples:

```yaml
{{- if and .Values.adminEmail (or .Values.serviceAccountJson .Values.existingSecret) }}
```

```yaml
{{- if (and (eq .Values.service.type "NodePort") (not (empty .Values.service.nodePort))) }}
```

```yaml
{{- if or .Values.rbac.pspEnabled (and .Values.rbac.namespaced .Values.sidecar.enabled) }}
```

## Flow control

### Conditions

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.service.name | default .Chart.Name }}
{{- end }}
```

`if`/`else if`/`else` are supported. `else if` is spelled `else if` in
Go templates, often written as `{{- else if ... }}`.

### Loops with `range`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
spec:
  rules:
  {{- range .Values.ingress.hosts }}
  - host: {{ .hostname | quote }}
    http:
      paths:
      {{- range .paths }}
      - path: {{ .path }}
        pathType: Prefix
        backend:
          service:
            name: {{ .service }}
            port:
              number: 80
      {{- end }}
  {{- end }}
```

Values:

```yaml
ingress:
  hosts:
    - hostname: frontend.local
      paths:
        - path: /public
          service: frontend
        - path: /admin
          service: admin
    - hostname: backend.local
      paths: []
```

## Variables

Declare variables with `:=`:

```yaml
{{- $defaultPortName := .Values.defaultPortName }}
spec:
  {{- with .Values.service }}
  type: {{ .type }}
  ports:
    - port: {{ .port }}
      targetPort: 80
      name: {{ $defaultPortName }}
  {{- end }}
```

Inside `range`, the current element is `.`, but you often need the root
context or the parent loop variable:

```yaml
{{- range $currentHost := .Values.ingress.hosts }}
  {{- $hostname := $currentHost.hostname }}
  - host: {{ $hostname | quote }}
    http:
      paths:
      {{- range .paths }}
      - path: {{ .path }}-{{ $hostname }}
        backend:
          service:
            name: {{ $.Release.Name }}-{{ .service }}
            port:
              number: 80
      {{- end }}
{{- end }}
```

- `$` always refers to the root context.
- `$currentHost` captures the outer loop element before entering the inner
  `range`, where `.` becomes the inner element.

## Named templates and helpers

Put reusable snippets in `templates/_helpers.tpl`. Files starting with `_`
are not rendered as Kubernetes objects.

```gotemplate
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
```

Use it:

```yaml
metadata:
  name: {{ include "mychart.fullname" . }}
```

`include` versus `template`:

- `template` inserts the rendered template but cannot be piped.
- `include` returns the rendered string, so it can be piped to `indent`,
  `nindent`, `quote`, etc.

```yaml
  labels:
{{ include "mychart.labels" . | indent 4 }}
```

## NOTES.txt

`templates/NOTES.txt` is rendered after install/upgrade and shown to the
user. It is not applied to the cluster. It is useful for next steps and
connection instructions.

```gotemplate
1. Get the application URL by running these commands:
{{- if .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
  {{- range .paths }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}{{ .path }}
  {{- end }}
{{- end }}
{{- else }}
  export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "mychart.fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  echo http://$SERVICE_IP:{{ .Values.service.port }}
{{- end }}
```

## Testing templates before install

| Approach | Command | Needs cluster? | Notes |
| --- | --- | --- | --- |
| Local render | `helm template <release> <chart>` | No | Uses static release name you provide |
| Dry run | `helm install <release> <chart> --dry-run --debug` | Yes | Real rendering, no commit |
| Lint | `helm lint <chart>` | No | Catches common chart issues |

```bash
helm template demo ./mychart
helm template demo ./mychart -f values-dev.yaml
helm install demo ./mychart --dry-run --debug
helm install demo ./mychart --dry-run --debug 2>&1 | less
```

## Common template pitfalls

| Pitfall | Fix |
| --- | --- |
| Values render as strings when a number is expected | Use `--set-string` carefully; quote only when needed |
| Missing newline or bad indentation | Use `{{-`, `-}}`, `indent`, `nindent` |
| `nil pointer evaluating interface` | Guard with `with`, `default`, or `hasKey` |
| Can't access root inside `range` | Use `$` |
| Named template cannot be piped | Use `include` instead of `template` |
| YAML interpreted as boolean/date | Quote strings such as `"yes"`, `"on"`, image tags |
| Secret is not base64 encoded | Pipe through `b64enc` |

## Key takeaways

- Templates turn one chart into many environment-specific releases.
- Values precedence: `--set` > `-f` > chart defaults (plus parent over
  child).
- Use built-in objects for release, chart, and cluster metadata.
- Use Sprig functions, pipelines, `with`, `range`, and variables for logic.
- Put reusable naming/label logic in `_helpers.tpl` and call it with
  `include`.
- Always render with `helm template` and dry-run before installing.
