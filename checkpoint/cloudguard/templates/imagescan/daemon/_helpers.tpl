{{- define "imagescan.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "imagescan" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan }}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.daemon }}
{{- if $config.featureConfig.enabled }}
{{- $_ := set $config "containerRuntime" (include "get.container.runtime" .) }}
{{- end }}
{{- $config | toYaml -}}
{{- end -}}

{{- define "imagescan.engine.resource.name" }}
{{- $engineConfig := fromYaml (include "imagescan.engine.config" . ) -}}
{{ template "agent.resource.name" $engineConfig }}
{{- end }}

{{- define "imagescan.daemon.shim.resources" }}
{{- if .agentConfig.shim.resources }}
{{- $resources := .agentConfig.shim.resources }}
{{- if eq .containerRuntime "cri-o" }}
{{- $resources = .agentConfig.shim.resources.crio }}
{{- end }}
resources:
  requests:
    cpu: {{ $resources.requests.cpu }}
    memory: {{ $resources.requests.memory }}
  limits:
    cpu: {{ $resources.limits.cpu }}
    memory: {{ $resources.limits.memory }}
{{- end }}
{{- end }} 