{{- define "runtime.policy.config" }}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "runtime" }}
{{- $_ := set $config "agentName" "policy" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.runtimeProtection }}
{{- $_ := set $config "agentConfig" $config.Values.addons.runtimeProtection.policy }}
{{- $config | toYaml -}}
{{- end -}}