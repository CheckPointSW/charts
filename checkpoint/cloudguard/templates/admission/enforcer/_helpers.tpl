{{- define "admission.enforcer.config" }}
{{- $config := . }}
{{- $_ := set $config "featureName" "admission" }}
{{- $_ := set $config "agentName" "enforcer" }}
{{- $_ := set $config "featureConfig" $.Values.addons.admissionControl }}
{{- $_ := set $config "agentConfig" $.Values.addons.admissionControl.enforcer }}
{{- $config | toYaml -}}
{{- end -}}
