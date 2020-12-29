{{- define "runtime.policy.config" }}
{{- $config := . }}
{{- $_ := set $config "featureName" "runtime" }}
{{- $_ := set $config "agentName" "policy" }}
{{- $_ := set $config "featureConfig" $.Values.addons.runtimeProtection }}
{{- $_ := set $config "agentConfig" $.Values.addons.runtimeProtection.policy }}
{{- $config | toYaml -}}
{{- end -}}