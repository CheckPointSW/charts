{{- /* return a dictionary of configs 
to get base config use helper "flowlogs.daemon.config"
usage:
`{{- $configs := include "flowlogs.daemon.config.multiple" . -}}`
*/ -}}
{{- define "flowlogs.daemon.config.multiple" -}}
{{- $config := fromYaml (include "flowlogs.daemon.config" . ) -}}
{{- include "common.daemonset.config.extract.multiple" (dict "config" $config) -}}
{{- end -}}

{{- /* helper to get the base config
usage:
`{{- $config := fromYaml (include "flowlogs.daemon.config" .) -}}`
*/ -}}
{{- define "flowlogs.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "flowlogs" -}}
{{- $_ := set $config "agentName" "daemon" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.flowLogs -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.flowLogs.daemon -}}
{{- $config | toYaml -}}
{{- end -}}