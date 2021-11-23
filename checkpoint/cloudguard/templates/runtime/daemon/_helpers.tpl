{{- define "runtime.daemon.config" }}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "runtime" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.runtimeProtection }}
{{- $_ := set $config "agentConfig" $config.Values.addons.runtimeProtection.daemon }}
{{- if $config.featureConfig.enabled }}
{{- $_ := set $config "containerRuntime" (include "get.container.runtime" .) }}
{{- end }}
{{- $config | toYaml -}}
{{- end -}}