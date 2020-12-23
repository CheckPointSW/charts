{{/*
Expand the name of the chart.
*/}}
{{- define "cp-resource-management.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cp-resource-management.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cp-resource-management.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "cp-resource-management.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "dome9.url" -}}
{{- $region := default "us1" (lower .Values.region) -}}
{{- if has $region (list "us1" "us") -}}
{{- printf "https://api-cpx.dome9.com" -}}
{{- else if has $region (list "eu1" "eu") -}}
{{- printf "https://api-cpx.eu1.dome9.com" -}}
{{- else if has $region (list "ap1" "ap") -}}
{{- printf "https://api-cpx.ap1.dome9.com" -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid region: %s (should be one of: 'US' [default], 'EU', 'AP')"  .Values.region -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}
