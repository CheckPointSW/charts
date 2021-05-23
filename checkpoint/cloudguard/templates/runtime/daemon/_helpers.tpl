{{- define "runtime.daemon.config" }}
{{- $config := . }}
{{- $_ := set $config "featureName" "runtime" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $.Values.addons.runtimeProtection }}
{{- $_ := set $config "agentConfig" $.Values.addons.runtimeProtection.daemon }}
{{- $config | toYaml -}}
{{- end -}}