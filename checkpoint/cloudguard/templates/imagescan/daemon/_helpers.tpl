{{- /* return a dictionary of configs 
to get base config use helper "imagescan.daemon.config"
usage:
`{{- $configs := include "imagescan.daemon.config.multiple" . -}}`
*/ -}}
{{- define "imagescan.daemon.config.multiple" -}}
{{- $config := fromYaml (include "imagescan.daemon.config" . ) -}}
{{- include "common.daemonset.config.extract.multiple" (dict "config" $config) -}}
{{- end -}}

{{- /* helper to get the base config
usage:
`{{- $config := fromYaml (include "imagescan.daemon.config" .) -}}`
*/ -}}
{{- define "imagescan.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "imagescan" -}}
{{- $_ := set $config "agentName" "daemon" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.imageScan -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.imageScan.daemon -}}
{{- $config | toYaml -}}
{{- end -}}


{{- define "imagescan.engine.resource.name" -}}
{{- $engineConfig := fromYaml (include "imagescan.engine.config" . ) -}}
{{ template "agent.resource.name" $engineConfig }}
{{- end -}}

{{- define "imagescan.daemon.shim.resources" -}}
{{- if .agentConfig.shim.resources -}}
{{- $resources := .agentConfig.shim.resources -}}
{{- if eq .containerRuntime "cri-o" -}}
{{- $resources = .agentConfig.shim.resources.crio -}}
{{- end -}}
resources:
  requests:
    cpu: {{ $resources.requests.cpu }}
    memory: {{ $resources.requests.memory }}
  limits:
    cpu: {{ $resources.limits.cpu }}
    memory: {{ $resources.limits.memory }}
{{- end -}}
{{- end -}} 
