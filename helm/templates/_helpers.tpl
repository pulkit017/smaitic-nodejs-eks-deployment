{{- define "node-api.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "node-api.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "node-api.labels" -}}
app.kubernetes.io/name: {{ include "node-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "node-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "node-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "node-api.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
