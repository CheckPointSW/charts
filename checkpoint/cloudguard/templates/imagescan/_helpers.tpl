{{- define "imagescan.engineAndList.commonFull.name" -}}
imagescan-engine
{{- end -}}

{{- define "imagescan.engineAndList.commonResource.name" -}}
{{- $agentFullName := include "imagescan.engineAndList.commonFull.name" . -}}
{{ printf "%s-%s" (include "name.prefix" .) $agentFullName }}
{{- end -}}