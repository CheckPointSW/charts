{{- define "imagescan.engine.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "imagescan" }}
{{- $_ := set $config "agentName" "engine" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan }}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.engine }}
{{- if $config.featureConfig.enabled }}
{{- $_ := set $config "containerRuntime" (include "get.container.runtime" .) }}
{{- end }}
{{- $config | toYaml -}}
{{- end -}}

{{- define "imagescan.daemon.resource.name" -}}
{{- $daemonConfig := fromYaml (include "imagescan.daemon.config" .) -}}
{{ template "agent.resource.name" $daemonConfig }}
{{- end -}}

{{- define "imagescan.engine.resources" -}}
{{- if .agentConfig.resources }}
resources:
  requests:
    cpu: {{ .agentConfig.resources.requests.cpu }}
    memory: {{ .agentConfig.resources.requests.memory }}
  limits:
    cpu: {{ .agentConfig.resources.limits.cpu }}
{{- if .featureConfig.maxImageSizeMb }}
{{- /* the memory consumption of imagescan engine is the largest image size it is configured to scan + 500Mi */}}
    memory: {{ add 500 .featureConfig.maxImageSizeMb }}Mi
{{- else }}
    memory: {{ .agentConfig.resources.limits.memory }}
{{- end }}
{{- end -}}
{{- end }}