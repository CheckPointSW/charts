{{- define "flowlogs.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "flowlogs" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.flowLogs }}
{{- $_ := set $config "agentConfig" $config.Values.addons.flowLogs.daemon }}
{{- $config | toYaml -}}
{{- end -}}