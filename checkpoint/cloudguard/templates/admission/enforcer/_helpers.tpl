{{- define "admission.enforcer.config" }}
{{- $config := . }}
{{- $_ := set $config "featureName" "admission" }}
{{- $_ := set $config "agentName" "enforcer" }}
{{- $_ := set $config "featureConfig" $.Values.addons.admissionControl }}
{{- $_ := set $config "agentConfig" $.Values.addons.admissionControl.enforcer }}
{{- $config | toYaml -}}
{{- end -}}

{{/*
Generate certificates for gsl-enforcer webhook 
*/}}
{{- define "gsl-enforcer.gen-certs" -}}
{{- $altNames := list ( printf "%s-admission-enforcer.%s" .Release.Name  .Release.Namespace ) ( printf "%s-admission-enforcer.%s.svc" .Release.Name .Release.Namespace ) -}}
{{- $cert := genSelfSignedCert  ( printf "%s-admission-enforcer" .Release.Name )  nil $altNames 3650 -}}
crt: {{ $cert.Cert | b64enc }}
key: {{ $cert.Key | b64enc }}
{{- end -}}
