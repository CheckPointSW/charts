{{- /* return a dictionary of configs 
to get base config use helper "runtime.daemon.config"
usage:
`{{- $configs := include "runtime.daemon.config.multiple" . -}}`
*/ -}}
{{- define "runtime.daemon.config.multiple" -}}
{{- $config := fromYaml (include "runtime.daemon.config" . ) -}}
{{- include "common.daemonset.config.extract.multiple" (dict "config" $config) -}}
{{- end -}}

{{- /* helper to get the base config
usage:
`{{- $config := fromYaml (include "runtime.daemon.config" .) -}}`
*/ -}}
{{- define "runtime.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "runtime" -}}
{{- $_ := set $config "agentName" "daemon" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.runtimeProtection -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.runtimeProtection.daemon -}}
{{- $config | toYaml -}}
{{- end -}}
