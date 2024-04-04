{{- define "imagescan.armon.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "imagescan" -}}
{{- $_ := set $config "agentName" "armon" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan -}}
{{- /*  special Case for fileaccess daemonSet name to be different than daemon*/ -}}
{{- $_ := set $config "daemonConfigName" "armon" -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.armon -}}
{{- $config | toYaml -}}
{{- end -}}
