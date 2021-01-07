{{- define "flowlogs.daemon.config" -}}
{{- $config := . }}
{{- $_ := set $config "featureName" "flowlogs" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $.Values.addons.flowLogs }}
{{- $_ := set $config "agentConfig" $.Values.addons.flowLogs.daemon }}
{{- $config | toYaml -}}
{{- end -}}