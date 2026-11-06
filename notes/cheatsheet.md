# Helm Cheatsheet

## Version and environment

```bash
helm version
helm env
helm help
helm <command> --help
```

## Repositories

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable   # deprecated content
helm repo list
helm repo update
helm repo remove bitnami
```

## Discover charts

```bash
helm search hub wordpress
helm search repo wordpress
helm search repo bitnami/wordpress --versions
helm show chart bitnami/wordpress
helm show values bitnami/wordpress
helm show readme bitnami/wordpress
helm show all bitnami/wordpress
helm pull bitnami/wordpress --untar --untardir ./vendor
```

## Create and validate a chart

```bash
helm create mychart
helm lint mychart
helm template demo mychart
helm template demo mychart -f values-dev.yaml
helm template demo mychart --set image.tag=1.2.3
helm install demo mychart --dry-run --debug
helm package mychart
helm package mychart --version 1.2.0 --app-version 2.4.1
```

## Release lifecycle

```bash
helm install demo ./mychart -n demo --create-namespace
helm install demo ./mychart -n demo -f values.yaml
helm install demo ./mychart -n demo --set replicaCount=3
helm install --generate-name ./mychart -n demo

helm list
helm list -A
helm list -n demo
helm status demo -n demo
helm history demo -n demo
helm get all demo -n demo
helm get values demo -n demo
helm get manifest demo -n demo

helm upgrade demo ./mychart -n demo
helm upgrade demo ./mychart -n demo --set image.tag=2.0.0
helm upgrade --install demo ./mychart -n demo --create-namespace

helm rollback demo 1 -n demo
helm uninstall demo -n demo
helm uninstall demo -n demo --keep-history
```

## Values precedence

Highest to lowest:

1. `--set`, `--set-string`, `--set-file`
2. `-f` files (later files win)
3. Parent chart `values.yaml` over subchart defaults
4. Subchart `values.yaml`

```bash
helm install demo ./mychart -f values.yaml -f values-prod.yaml
helm install demo ./mychart --set service.type=NodePort
helm install demo ./mychart --set-string image.tag=1.10
helm install demo ./mychart --set-file config=./config.txt
helm install demo ./mychart --set 'ingress.hosts[0].host=example.local'
```

## Dependencies

```bash
helm dependency list mychart
helm dependency update mychart
helm dependency build mychart
```

`Chart.yaml` fragment:

```yaml
dependencies:
  - name: mongodb
    version: ~15.6.0
    repository: https://charts.bitnami.com/bitnami
    condition: mongodb.enabled
    tags:
      - database
    import-values:
      - child: data
        parent: db
```

`values.yaml` fragment:

```yaml
mongodb:
  enabled: true
tags:
  database: true
```

## Repository publishing

```bash
helm package mychart --destination ./dist
helm repo index ./dist --url https://charts.example.com
# upload ./dist/*.tgz and ./dist/index.yaml to the web server
helm repo add myrepo https://charts.example.com
helm repo update
helm search repo myrepo/mychart
```

Provenance (optional):

```bash
helm package --sign --key '<key>' --keyring ~/.gnupg/secring.gpg mychart
helm verify mychart-1.2.0.tgz
helm install demo myrepo/mychart --verify
```

## Named templates

```gotemplate
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```

```yaml
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
{{ include "mychart.labels" . | nindent 4 }}
```

## Template snippets

```yaml
# Default value
name: {{ .Values.name | default .Chart.Name }}

# Quote
value: {{ .Values.value | quote }}

# Base64 for Secret data
password: {{ .Values.password | b64enc | quote }}

# Safe YAML block
annotations:
  {{- toYaml .Values.annotations | nindent 2 }}

# Conditional block
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
{{- end }}

# Loop
{{- range .Values.hosts }}
- host: {{ .host | quote }}
{{- end }}

# Scope change
{{- with .Values.service }}
type: {{ .type }}
port: {{ .port }}
{{- end }}

# Variable
{{- $name := .Values.name }}
```

## Built-in objects

| Object | Examples |
| --- | --- |
| `.Release` | `.Release.Name`, `.Release.Namespace`, `.Release.Revision`, `.Release.IsInstall`, `.Release.IsUpgrade` |
| `.Chart` | `.Chart.Name`, `.Chart.Version`, `.Chart.AppVersion` |
| `.Capabilities` | `.Capabilities.KubeVersion`, `.Capabilities.APIVersions` |
| `.Template` | `.Template.Name`, `.Template.BasePath` |
| `.Files` | `.Files.Get "file.txt"` |

## Troubleshooting quick checks

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
helm list -A
helm status <release> -n <namespace>
helm history <release> -n <namespace>
helm get manifest <release> -n <namespace>
helm template <release> <chart> --debug
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl describe <kind> <name> -n <namespace>
kubectl logs <pod> -n <namespace>
```
