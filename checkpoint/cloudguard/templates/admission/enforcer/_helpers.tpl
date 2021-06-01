{{- define "admission.enforcer.config" }}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "admission" }}
{{- $_ := set $config "agentName" "enforcer" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.admissionControl }}
{{- $_ := set $config "agentConfig" $config.Values.addons.admissionControl.enforcer }}
{{- $config | toYaml -}}
{{- end -}}
