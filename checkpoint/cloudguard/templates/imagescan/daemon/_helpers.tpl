{{- define "imagescan.daemon.config" -}}
{{- $config := . }}
{{- $_ := set $config "featureName" "imagescan" }}
{{- $_ := set $config "agentName" "daemon" }}
{{- $_ := set $config "featureConfig" $.Values.addons.imageScan }}
{{- $_ := set $config "agentConfig" $.Values.addons.imageScan.daemon }}
{{- $config | toYaml -}}
{{- end -}}

{{- define "imagescan.engine.resource.name" -}}
{{- $engineConfig := fromYaml (include "imagescan.engine.config" .) -}}
{{ template "agent.resource.name" $engineConfig }}
{{- end -}}