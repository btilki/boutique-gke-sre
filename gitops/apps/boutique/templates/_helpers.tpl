{{/*
Expand the name of the chart.
*/}}
{{- define "boutique.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all Boutique workloads.
*/}}
{{- define "boutique.labels" -}}
app.kubernetes.io/name: {{ .appLabel }}
app.kubernetes.io/instance: {{ $.Release.Name }}
app.kubernetes.io/part-of: {{ .Values.global.partOf }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app: {{ .appLabel }}
{{- end }}

{{/*
Pod selector labels — must stay stable across upgrades.
*/}}
{{- define "boutique.selectorLabels" -}}
app.kubernetes.io/name: {{ .appLabel }}
app.kubernetes.io/instance: {{ $.Release.Name }}
app: {{ .appLabel }}
{{- end }}

{{/*
Digest-pinned image reference from values-images.yaml.
*/}}
{{- define "boutique.image" -}}
{{- $image := index .root.Values.images .imageKey -}}
{{- printf "%s@%s" $image.repository $image.digest }}
{{- end }}

{{/*
Liveness probe — HTTP for web services, TCP for gRPC.
Optional per-service overrides via livenessPath / livenessHeaders in probe dict.
*/}}
{{- define "boutique.livenessProbe" -}}
{{- if eq .protocol "http" }}
httpGet:
  path: {{ default "/" .livenessPath }}
  port: {{ .port }}
  {{- with .livenessHeaders }}
  httpHeaders:
    {{- toYaml . | nindent 4 }}
  {{- end }}
initialDelaySeconds: {{ default 10 .livenessInitialDelaySeconds }}
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 3
{{- else }}
tcpSocket:
  port: {{ .port }}
initialDelaySeconds: {{ default 15 .livenessInitialDelaySeconds }}
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 3
{{- end }}
{{- end }}

{{/*
Readiness probe — HTTP for web services, TCP for gRPC.
Optional per-service overrides via readinessPath / readinessHeaders in probe dict.
*/}}
{{- define "boutique.readinessProbe" -}}
{{- if eq .protocol "http" }}
httpGet:
  path: {{ default "/" .readinessPath }}
  port: {{ .port }}
  {{- with .readinessHeaders }}
  httpHeaders:
    {{- toYaml . | nindent 4 }}
  {{- end }}
initialDelaySeconds: {{ default 5 .readinessInitialDelaySeconds }}
periodSeconds: 5
timeoutSeconds: 3
failureThreshold: 3
{{- else }}
tcpSocket:
  port: {{ .port }}
initialDelaySeconds: {{ default 10 .readinessInitialDelaySeconds }}
periodSeconds: 5
timeoutSeconds: 3
failureThreshold: 3
{{- end }}
{{- end }}
