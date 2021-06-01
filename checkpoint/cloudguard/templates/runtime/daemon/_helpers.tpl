{{- define "runtime.daemon.config" }}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "runtime" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.runtimeProtection }}
{{- $_ := set $config "agentConfig" $config.Values.addons.runtimeProtection.daemon }}
{{- $config | toYaml -}}
{{- end -}}