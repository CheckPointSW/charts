{{- /* return a dictionary of configs 
to get base config use helper "runtime.daemon.config"
usage:
`{{- $configs := include "runtime.daemon.config.multiple" . -}}`
*/ -}}
{{- define "runtime.daemon.config.multiple" -}}
{{- $config := fromYaml (include "runtime.daemon.config" . ) -}}
{{- include "common.daemonset.config.extract.multiple" (dict "config" $config) -}}
{{- end -}}

{{- /* helper to get the base config
usage:
`{{- $config := fromYaml (include "runtime.daemon.config" .) -}}`
*/ -}}
{{- define "runtime.daemon.config" -}}
{{- $config := (include "get.root" .) | fromYaml -}}
{{- $_ := set $config "featureName" "runtime" -}}
{{- $_ := set $config "agentName" "daemon" -}}
{{- $_ := set $config "featureConfig" $config.Values.addons.runtimeProtection -}}
{{- $_ := set $config "agentConfig" $config.Values.addons.runtimeProtection.daemon -}}
{{- $config | toYaml -}}
{{- end -}}


{{- /* App armor annotation K8s version < 1.30 */ -}}
{{- define "runtime.daemon.apparmor.annotation" -}}
{{- if semverCompare "<1.30-0" .Capabilities.KubeVersion.Version -}}
container.apparmor.security.beta.kubernetes.io/daemon: unconfined
{{- end -}}
{{- end -}}

{{- /* App armor annotation K8s version > 1.30 */ -}}
{{- define "runtime.daemon.apparmor.securityContext" -}}
{{- if semverCompare ">=1.30-0" .Capabilities.KubeVersion.Version -}}
appArmorProfile:
    type: Unconfined
{{- end -}}
{{- end -}}