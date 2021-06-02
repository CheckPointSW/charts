{{- define "imagescan.engine.config" -}}
{{- $config := (include "get.root" .) | fromYaml }}
{{- $_ := set $config "featureName" "imagescan" }}
{{- $_ := set $config "agentName" "engine" }}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan }}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.engine }}
{{- $config | toYaml -}}
{{- end -}}

{{- define "imagescan.daemon.resource.name" -}}
{{- $daemonConfig := fromYaml (include "imagescan.daemon.config" .) -}}
{{ template "agent.resource.name" $daemonConfig }}
{{- end -}}

{{- define "imagescan.engine.resources" -}}
{{- if .agentConfig.resources }}
resources:
  limits:
    cpu: {{ .agentConfig.resources.limits.cpu }}
{{- if .featureConfig.maxImageSizeMb }}
    memory: {{ mul 2 .featureConfig.maxImageSizeMb }}Mi
{{- else }}
    memory: {{ .agentConfig.resources.limits.memory }}
{{- end }}
  requests:
    cpu: {{ .agentConfig.resources.requests.cpu }}
    memory: {{ .agentConfig.resources.requests.memory }}
{{- end -}}
{{- end }}