{{- define "inventory.agent.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "inventory" }}
{{- $_ := set $config "agentName" "agent" }}
{{- $_ := set $config "featureConfig" $config.Values.inventory }}

{{- /* telemetry templates check if "featureConfig.enabled" is true,
       for inventory this parameter is missing from defaults/values on purpose
    */ -}}
{{- $_ := set $config.featureConfig "enabled" true }}
{{- $_ := set $config "agentConfig" $config.Values.inventory.agent }}
{{- $config | toYaml -}}
{{- end -}}
