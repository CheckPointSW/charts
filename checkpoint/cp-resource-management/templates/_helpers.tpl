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

{{/*
  Return Dome9 subdomain in format xxN e.g. "eu1", "ap3" etc. For us* only return an empty string
*/}}
{{- define "dome9.subdomain" -}}
{{- $datacenter := lower $.Values.datacenter -}}
{{- if has $datacenter (list "us" "us1" "usea1") -}}
{{- printf "" -}}
{{- else if has $datacenter (list "eu" "eu1" "euwe1") -}}
{{- printf "eu1" -}}
{{- else if has $datacenter (list "ap" "ap1" "apse1") -}}
{{- printf "ap1" -}}
{{- else if has $datacenter (list "ap2" "apse2") -}}
{{- printf "ap2" -}}
{{- else if has $datacenter (list "ap3" "apso1") -}}
{{- printf "ap3" -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid datacenter: %s (should be one of: 'usea1' [default], 'euwe1', 'apse1', 'apse2', 'apso1')"  $.Values.datacenter -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{/*
  Return backend URL
*/}}
{{- define "dome9.url" -}}
{{- if $.Values.cloudguardURL -}}
{{- printf "%s" $.Values.cloudguardURL -}}
{{- else -}}
{{- $subdomain := (include "dome9.subdomain" .) -}}
{{- if eq $subdomain "" -}}
{{- printf "https://api-cpx.dome9.com" -}}
{{- else -}}
{{- printf "https://api-cpx.%s.dome9.com" $subdomain -}}
{{- end -}}
{{- end -}}
{{- end -}}