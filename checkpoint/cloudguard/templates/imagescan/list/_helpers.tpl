{{- define "imagescan.list.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "imagescan" -}}
{{- $_ := set $config "agentName" "list" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.list -}}
{{- $config | toYaml -}}
{{- end -}}