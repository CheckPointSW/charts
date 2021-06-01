{{- define "admission.policy.config" }}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "admission" }}
{{- $_ := set $config "agentName" "policy" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.admissionControl }}
{{- $_ := set $config "agentConfig" $config.Values.addons.admissionControl.policy }}
{{- $config | toYaml -}}
{{- end -}}