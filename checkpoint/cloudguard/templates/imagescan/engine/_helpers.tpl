{{- define "imagescan.engine.config" -}}
{{- $config := . }}
{{- $_ := set $config "featureName" "imagescan" }}
{{- $_ := set $config "agentName" "engine" }}
{{- $_ := set $config "featureConfig" $.Values.addons.imageScan }}
{{- $_ := set $config "agentConfig" $.Values.addons.imageScan.engine }}
{{- $config | toYaml -}}
{{- end -}}

{{- define "imagescan.daemon.resource.name" -}}
{{- $daemonConfig := fromYaml (include "imagescan.daemon.config" .) -}}
{{ template "agent.resource.name" $daemonConfig }}
{{- end -}}