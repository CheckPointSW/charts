{{- define "inventory.agent.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "inventory" }}
{{- $_ := set $config "agentName" "agent" }}
{{- $_ := set $config "featureConfig" $config.Values.inventory }}
{{- $_ := set $config "agentConfig" $config.Values.inventory.agent }}
{{- $config | toYaml -}}
{{- end -}}