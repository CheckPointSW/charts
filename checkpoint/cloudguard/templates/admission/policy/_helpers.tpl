{{- define "admission.policy.config" }}
{{- $config := . }}
{{- $_ := set $config "featureName" "admission" }}
{{- $_ := set $config "agentName" "policy" }}
{{- $_ := set $config "featureConfig" $.Values.addons.admissionControl }}
{{- $_ := set $config "agentConfig" $.Values.addons.admissionControl.policy }}
{{- $config | toYaml -}}
{{- end -}}