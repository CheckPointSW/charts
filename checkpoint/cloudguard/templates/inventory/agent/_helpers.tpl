{{- define "inventory.agent.config" -}}
{{- $config := . }}
{{- $_ := set $config "featureName" "inventory" }}
{{- $_ := set $config "agentName" "agent" }}
{{- $_ := set $config "featureConfig" $.Values.inventory }}
{{- $_ := set $config "agentConfig" $.Values.inventory.agent }}
{{- $config | toYaml -}}
{{- end -}}