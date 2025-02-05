{{/* Parse cloudguardURL and create variables for specific parts of the URL */}}
{{- define "cloudguardURL_host" -}}
{{- ( include "dome9.url" . | urlParse ).host -}}
{{- end -}}

{{- define "cloudguardURL_path" -}}
{{- printf "%s/" (( include "dome9.url" . | urlParse ).path) -}}
{{- end -}}

{{- /* Return prefix for resource names. 
       By default, helm release name is used. However, on GKE Autopilot, 
       fixed prefix "cloudguard" is used (to enable whitelisting)
    */ -}}
{{- define "name.prefix" -}}
{{-   if eq .platform "gke.autopilot" -}}
{{-     printf "cloudguard" -}}
{{-   else -}}
{{-     printf "%s" .Release.Name -}}
{{-   end -}}
{{- end -}}

{{- /* The following templates are invoked with a per-agent 'config' object, containing:
        - .featureName (e.g., imagescan)
        - .agentName (e.g., daemon)
        - .featureConfig (e.g., .Values.addons.imagescan)
        - .agentConfig (e.g., .Values.addons.imagescan.daemon)
        - .Values - merged content of provided defaults.yaml, values.yaml and values provided during installation (CLI and values file)
    */ -}}
{{- define "agent.full.name" -}}
{{ printf "%s-%s" .featureName .agentName }}
{{- end -}}

{{- /* Common resource for a given agent, following the naming convention */ -}}
{{- define "agent.resource.name" -}}
{{- $agentFullName := include "agent.full.name" . -}}
{{ printf "%s-%s" (include "name.prefix" .) $agentFullName }}
{{- end -}}


{{- /* special Case for daemonSet name following the naming convention */ -}}
{{- define "daemonset.daemon.resource.name" -}}
{{ printf "%s-%s-%s" (include "name.prefix" .) .featureName .daemonConfigName }}
{{- end -}}

{{- /* Service account name of a given agent (provided in values.yaml or auto-generated) */ -}}
{{- define "agent.service.account.name" -}}
{{- default (include "agent.resource.name" .) .agentConfig.serviceAccountName }}
{{- end -}}

{{- /* Full path to the image of the main container of the provided agent. in case of autoUpgrade enabled we use the version without the patch */ -}}
{{- define "agent.main.image" -}}
{{-     $tag := .agentConfig.tag }}
{{-     if or .Values.debugImages .featureConfig.debugImages .agentConfig.debugImages }}
{{-         $tag = printf "%s-debug" .agentConfig.tag }}
{{-     end }}
{{-     if and (eq (include "get.autoUpgrade" .) "true") (regexMatch "^\\d+.\\d+.\\d+$" $tag) -}}
{{-         $tag = regexFind "\\d+.\\d+" $tag }}
{{-     end -}}
{{-     $image := printf "%s/%s:%s" .Values.imageRegistry.url .agentConfig.image $tag }}
{{-     default $image .agentConfig.fullImage }}
{{- end -}}

{{- /* Full path to the image of a provided side-car container. in case of autoUpgrade enabled we use the version without the patch */ -}}
{{- define "agent.sidecar.image" -}}
{{-     $containerConfig := get .agentConfig .containerName }}
{{-     $tag := $containerConfig.tag }}
{{-     if or .Values.debugImages .featureConfig.debugImages .agentConfig.debugImages $containerConfig.debugImage }}
{{-         $tag = printf "%s-debug" $containerConfig.tag }}
{{-     end }}
{{-     if and (eq (include "get.autoUpgrade" .) "true") (regexMatch "^\\d+.\\d+.\\d+$" $tag) (ne $containerConfig.image "checkpoint/consec-runtime-probe") (ne $containerConfig.image "checkpoint/consec-runtime-cos-compat") -}}
{{-         $tag = regexFind "\\d+.\\d+" $tag }}
{{-     end -}}
{{-     $image := printf "%s/%s:%s" .Values.imageRegistry.url $containerConfig.image $tag }}
{{-     default $image $containerConfig.fullImage }}
{{- end -}}

{{- /* Labels commonly used in our selectors - don't use anywhere else
usage: `{{- include "common.selector.labels" $config -}}`
*/ -}}
{{- define "common.selector.labels" -}}
app.kubernetes.io/name: {{ include "agent.resource.name" . }}
app.kubernetes.io/instance: {{ include "name.prefix" . }}
{{- end -}}

{{- /* Labels commonly used in our "pod group" resources */ -}}
{{- define "common.labels.with.chart" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.name .Chart.version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/version: {{ $.Chart.appVersion }}
app.created.by.template: {{ (include "is.helm.template.command" .) | quote }}
{{ include "common.selector.labels" . }}
{{- end -}}

{{- /* Pod annotations commonly used in agents */ -}}
{{- define "common.pod.annotations" -}}
{{- /* workloads would restart upon some configurations change */ -}}
{{- include "annotations.sha256" . -}}
{{- /* Openshift does not allow seccomp - So we don't add seccomp in openshift case */ -}}
{{- /* From k8s 1.19 and up we use the seccomp in securityContext so no need for it here, in case of template we don't know the version so we fall back to annotation */ -}}
{{- if and (not (contains "openshift" .platform)) (semverCompare "<1.19-0" .Capabilities.KubeVersion.Version) }}
seccomp.security.alpha.kubernetes.io/pod: {{ .Values.podAnnotations.seccomp }}
{{- end }}
{{- if .Values.podAnnotations }}
{{- if .Values.podAnnotations.custom }}
{{ toYaml .Values.podAnnotations.custom }}
{{- end }}
{{- end }}
{{- if .agentConfig.podAnnotations }}
{{- if .agentConfig.podAnnotations.custom }}
{{ toYaml .agentConfig.podAnnotations.custom }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "common.pod.priorityClassName" -}}
{{- $priorityClassName := coalesce .agentConfig.priorityClassName .featureConfig.priorityClassName .Values.priorityClassName -}}
{{- printf "%s" $priorityClassName -}}
{{- end -}}

{{- /* Pod properties commonly used in agents */ -}}
{{- define "common.pod.properties" -}}
{{- $priorityClassName :=  (include "common.pod.priorityClassName" . ) -}}
{{- if $priorityClassName -}}
priorityClassName: {{ $priorityClassName }}
{{- end -}}
{{- if not (contains "openshift" .platform) }}
securityContext:
  runAsUser: {{ include "cloudguard.nonroot.user" . }}
  runAsGroup: {{ include "cloudguard.nonroot.user" . }}
{{- if (semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version) }}
  seccompProfile:
{{ toYaml .Values.seccompProfile | indent 4 }}
{{- end -}}
{{- end }}
serviceAccountName: {{ template "agent.service.account.name" . }}
{{- if .agentConfig.nodeSelector }}
nodeSelector:
{{ toYaml .agentConfig.nodeSelector | indent 2 }}
{{- end }}
affinity:
{{ include "common.pod.properties.affinity" . | indent 2 }}
{{- if .agentConfig.tolerations }}
tolerations:
{{ toYaml .agentConfig.tolerations | indent 2 }}
{{- end -}}
{{- if .Values.imageRegistry.authEnabled }}
imagePullSecrets:
- name: {{ include "name.prefix" . }}-regcred
{{- end -}}
{{- end -}}


{{- /* Extra Environment variables provided by the user for a given agent */ -}}
{{- define "user.defined.env" -}}
{{- if .agentConfig.env }}
{{ toYaml .agentConfig.env }}
{{- end -}}
{{- end -}}

{{- /* Environment variables commonly used in agents */ -}}
{{- define "common.env" -}}
- name: DOME9_URL
  value: {{ template "dome9.url" . }}
- name: CP_KUBERNETES_CLUSTER_ID
  valueFrom:
    configMapKeyRef:
      name: {{ include "name.prefix" . }}-cp-cloudguard-configmap
      key: clusterID
- name: NAMESPACE_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: PLATFORM
  value: {{ .platform }}
{{- if ne .platform "gke.autopilot" }}
- name: AUTO_UPGRADE_ENABLED
  value: {{ (include "get.autoUpgrade" .) | quote }}
{{- end -}}
{{- if .Values.proxy }}
- name: HTTPS_PROXY
  value: "{{ .Values.proxy }}"
- name: NO_PROXY
  value: "kubernetes.default.svc"
{{- end -}}

{{- template "user.defined.env" . -}}
{{- end -}}

{{- define "cloudguard.nonroot.user" -}}
17112
{{- end -}}

{{/*
Generate self-signed certificate with 'featureName-agentName.Namespace' structure
e.g. imagescan-daemon.checkpoint
*/}}
{{- define "generate.selfsigned.cert" -}}
{{- $serverName := (include "agent.resource.name" .) -}}
{{- $altNames := list $serverName ( printf "%s.%s" $serverName .Release.Namespace) ( printf "%s.%s.svc" $serverName .Release.Namespace) -}}
{{- $cert := genSelfSignedCert $serverName nil $altNames 3650 -}}
crt: {{ $cert.Cert | b64enc }}
key: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
  Return Dome9 subdomain in format xxN e.g. "eu1", "ap3" etc. For us* only return an empty string
*/}}
{{- define "dome9.subdomain" -}}
{{- $datacenter := lower .Values.datacenter -}}
{{- if has $datacenter (list "us" "us1" "usea1") -}}
{{- printf "" -}}
{{- else if has $datacenter (list "eu" "eu1" "euwe1") -}}
{{- printf "eu1" -}}
{{- else if has $datacenter (list "ap" "ap1" "apse1") -}}
{{- printf "ap1" -}}
{{- else if has $datacenter (list "ap2" "apse2") -}}
{{- printf "ap2" -}}
{{- else if has $datacenter (list "ap3" "apso1") -}}
{{- printf "ap3" -}}
{{- else if has $datacenter (list "ca" "ca1" "cace1") -}}
{{- printf "cace1" -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid datacenter: %s (should be one of: 'usea1' [default], 'euwe1', 'apse1', 'apse2', 'apso1', 'cace1')"  .Values.datacenter -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{/*
  Return backend URL
*/}}
{{- define "dome9.url" -}}
{{- if .Values.cloudguardURL -}}
{{- printf "%s" .Values.cloudguardURL -}}
{{- else -}}
{{- $subdomain := (include "dome9.subdomain" .) -}}
{{- if eq $subdomain "" -}}
{{- printf "https://api-cpx.dome9.com" -}}
{{- else -}}
{{- printf "https://api-cpx.%s.dome9.com" $subdomain -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
  Generate the .dockerconfigjson file unencoded.
*/}}
{{- define "dockerconfigjson.b64enc" -}}
    {{- $err := "Must disable .imageRegistry.authEnabled or specify .imageRegistry.user and .password" -}}
    {{- $user := required $err .Values.imageRegistry.user -}}
    {{- $pass := required $err .Values.imageRegistry.password -}}
    {{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .Values.imageRegistry.url (printf "%s:%s" $user $pass | b64enc) | b64enc -}}
{{- end -}}

{{- /* validate containerRuntime is one of the supported values. 
takes a context (such as $config, .Values or (dict "containerRuntime" $containerRuntime)) that has a .containerRuntime field */ -}}
{{- define "validate.container.runtime" -}}
{{- $supportedRuntimes := (include "supported.containerRuntimes" .) | splitList " " -}}
{{- if has (.containerRuntime | lower) $supportedRuntimes -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid containerRuntime: %s (should be one of: %s)" .containerRuntime $supportedRuntimes -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{/*
  Construct "root" context (dict) from defaults.yaml included in the chart and the effective .Values of the release (overriding defaults)
*/}}
{{- define "get.root" -}}
{{- if not (hasKey .Values "rootCache") -}}
{{- $defaults := (.Files.Get "defaults.yaml" | fromYaml ) -}}
{{- $merged := deepCopy . | mustMergeOverwrite (dict "Values" $defaults) -}}
{{- $_ := set $merged "containerRuntime" (include "get.container.runtime" $merged) -}}
{{- $_ := set $merged "platform" (include "get.platform" $merged) -}}
{{- /* Make ".Files" of the chart accessible and properly formatted when accessed via $config' */ -}}
{{- $_ := set $merged "Files" .Files -}}
{{- $_ := set .Values "rootCache" $merged -}}
{{- end -}}
{{- .Values.rootCache | toYaml -}}
{{- end -}}


{{- /* get the first node from the cluster */ -}}
{{- define "get.first.node" -}}
{{-   $nodes := lookup "v1" "Node" "" "" -}}
{{-   if empty $nodes -}}
{{-   else if eq (len $nodes.items) 0 -}}
{{-   else -}}
{{-     first $nodes.items | toYaml -}}
{{-   end -}}
{{- end -}}


{{- define "get.container.runtime" -}}
{{-   if .Values.containerRuntime -}}
{{-     include "validate.container.runtime" .Values -}}
{{      .Values.containerRuntime | lower }}
{{-   else -}}
{{-     $noRuntimeErr := "\n\nERROR: No nodes found, cannot identify container runtime. Use '--set containerRuntime=docker' or '--set containerRuntime=containerd' or '--set containerRuntime=cri-o'" -}}
{{-     $firstNode :=  include "get.first.node" . | fromYaml -}}
{{-     if empty $firstNode -}}
{{-       fail $noRuntimeErr -}}
{{-     end -}}
{{/*    examples for runtime version: docker://19.3.3, containerd://1.3.3, cri-o://1.20.3 */}}
{{-     $containerRuntimeVersion := $firstNode.status.nodeInfo.containerRuntimeVersion -}}
{{-     $containerRuntime := first (regexSplit ":" $containerRuntimeVersion -1) -}}
{{-     include "validate.container.runtime" (dict "containerRuntime" $containerRuntime) -}}
{{ $containerRuntime | lower }}
{{-   end -}}
{{- end -}}


{{- /* get platform value, if not provided, try to infer it from the first node */ -}}
{{- define "get.platform" -}}
{{- /* use platform value if it's a helm template command or when the provided value is not the default kubernetes */ -}}
{{-   if or (eq (include "is.helm.template.command" .) "true") (and .Values.platform (ne .Values.platform "kubernetes")) -}}
{{-     include "validate.platform" .Values -}}
{{-     lower .Values.platform -}}
{{-   else if has "config.openshift.io/v1" .Capabilities.APIVersions -}}
{{-     printf "openshift" -}}
{{-   else if has "security.openshift.io/v1" .Capabilities.APIVersions -}}
{{-     printf "openshift.v3" -}}
{{-   else if has "nsx.vmware.com/v1" .Capabilities.APIVersions -}}
{{-     printf "tanzu" -}}
{{/*   else if has "auto.gke.io/v1" .Capabilities.APIVersions */}}
{{/*     printf "gke.autopilot" */}}
{{-   else -}}
{{-     $supportedPlatforms := (include "supported.platforms" .) | splitList " " -}}
{{-     $noPlatformErr := printf "\n\nERROR: No nodes found, cannot identify platform. Append '--set platform=<platform>', platform should be one of %s" $supportedPlatforms -}}
{{-     $firstNode :=  include "get.first.node" . | fromYaml -}}
{{-     if empty $firstNode -}}
{{-       fail $noPlatformErr -}}
{{-     end -}}
{{-     $osImage := $firstNode.status.nodeInfo.osImage -}}
{{/*
        nodeInfo.osImage example values:
        - "Bottlerocket OS 1.7.2 (aws-k8s-1.21)"
        - "Container-Optimized OS from Google"
*/}}
{{-     if contains "Bottlerocket" $osImage -}}
{{-       printf "eks.bottlerocket" -}}
{{-     else if contains "Container-Optimized" $osImage -}}
{{-       printf "gke.cos" -}}
{{-     else if contains "Fedora CoreOS" $osImage -}}
{{-       printf "kubernetes.coreos" -}}
{{-     else if hasKey $firstNode.metadata.annotations "k3s.io/hostname"  -}}
{{-       printf "k3s" -}}
{{-     else if hasKey $firstNode.metadata.annotations "rke2.io/hostname"  -}}
{{-       printf "rke2" -}}
{{-     else if or (hasKey $firstNode.metadata.labels "eks.amazonaws.com/nodegroup") (hasKey $firstNode.metadata.labels "alpha.eksctl.io/nodegroup-name") (hasKey $firstNode.metadata.labels "eks.amazonaws.com/compute-type") -}}
{{-       printf "eks" -}}
{{-     else -}}
{{-       include "validate.platform" .Values -}}
{{-       lower .Values.platform -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{- define "inventory.resource.name" -}}
    {{- $inventoryConfig := fromYaml (include "inventory.agent.config" .) -}}
    {{ template "agent.resource.name" $inventoryConfig }}
{{- end }}

{{/*
If the registry is not "quay" do not enable automatic upgrades.
If platform is gke.autopilot do not enable automatic upgrades.
If a user manually defines a value, that choice takes precedence.
If a user opts for the default "preserve" option:
	If there was no prior deployment, automatic upgrades are enabled.
	If there was a previous deployment, we examine the value that deployment had and apply it.
	If there was no previous value, automatic upgrades are enabled.
	note: In the case of Helm templates, we won't have knowledge of the previous value, and unless a value is provided, "autoUpgrade" will default to "true"
 */}}
{{- define "get.autoUpgrade" -}}
{{-     if ne .Values.imageRegistry.url "quay.io" -}}
{{-         printf "false" -}}
{{-     else -}}
{{-         if or (eq (.Values.autoUpgrade | toString) "false") (eq .platform "gke.autopilot") -}}
{{-             printf "false" -}}
{{-         else -}}
{{-             if eq (.Values.autoUpgrade | toString) "true" -}}
{{-                 printf "true" -}}
{{-             else -}}
{{/*            preserve */}}
{{-                 $inventoryDeploymentName := trim (include "inventory.resource.name" .) -}}
{{-                 $inventoryDeployment := lookup "apps/v1" "Deployment" .Release.Namespace $inventoryDeploymentName -}}
{{-                 if not $inventoryDeployment -}}
{{-                     printf "true" -}}
{{-                 else -}}
{{-                     $isAutoUpgradeEnv := true -}}
{{-                     $firstContainer := first $inventoryDeployment.spec.template.spec.containers -}}
{{-                     range $index, $env := $firstContainer.env -}}
{{-                         if eq $env.name "AUTO_UPGRADE_ENABLED"}}
{{-                             if eq $env.value "false" -}}
{{-                                 $isAutoUpgradeEnv = false -}}
{{-                             end -}}
{{-                         end -}}
{{-                     end -}}
{{-                     printf ($isAutoUpgradeEnv | toString) -}}
{{-                 end -}}
{{-             end -}}
{{-         end -}}
{{-     end -}}
{{- end -}}

{{- /*
  use to know if we run from template (which mean wo have no connection to the cluster and cannot check Capabilities/nodes etc.)
  if there is no namespace probably we are running template
  returns string value "true" or "false"
  usage:
  `{{- if eq (include "is.helm.template.command") "true" -}}`
*/ -}}
{{- define "is.helm.template.command" -}}
{{- if not (hasKey .Values "isHelmTemplateCache") -}}
{{- $namespace := lookup "v1" "Namespace" "" "" -}}
{{- $_ := set .Values "isHelmTemplateCache" (eq (len $namespace) 0) -}}
{{- end -}}
{{- .Values.isHelmTemplateCache | toYaml -}}
{{- end -}}

{{- define "containerd.sock.path" -}}
{{-   if .Values.containerRuntimeSocket -}}
{{/*    container runtime socket path validation: should contain '/run/' substring and end with '.sock' */}}
{{-     if or (not (contains "/run" .Values.containerRuntimeSocket)) (not (hasSuffix ".sock" .Values.containerRuntimeSocket)) -}}
{{-       $err := printf "\n\nERROR: Invalid container runtime socket path: '%s' (should contain '/run' substring and end with '.sock'.)"  .Values.containerRuntimeSocket -}}
{{-       fail $err -}} 
{{-     end -}}
{{      printf (.Values.containerRuntimeSocket | toString) }}
{{-   else if eq .platform "eks.bottlerocket" -}}
{{-     printf "/run/dockershim.sock" -}}
{{-   else if has .platform (list "k3s" "rke2") -}}
{{-     printf "/run/k3s/containerd/containerd.sock" -}}
{{-   else -}}
{{-     printf "/run/containerd/containerd.sock" -}}
{{-   end -}}
{{- end -}}

{{- define "containerd.runtime.v2.task" -}}
{{-   if has .platform (list "k3s" "rke2") -}}
{{-     printf "/run/k3s/containerd/io.containerd.runtime.v2.task" -}}
{{-   else -}}
{{-     printf "/run/containerd/io.containerd.runtime.v2.task" -}}
{{-   end -}}
{{- end -}}

{{- /* validate platform is one of the supported values. 
takes a context (such as $config or .Values) that has a .platform field */ -}}
{{- define "validate.platform" -}}
{{- $supportedPlatforms := (include "supported.platforms" .) | splitList " " -}}
{{- if has (.platform | lower) $supportedPlatforms -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid platform: %s, should be one of: %s" .platform $supportedPlatforms -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{- define "daemonset.updateStrategy" -}}
updateStrategy:
  rollingUpdate:
    maxUnavailable: {{ .Values.daemonSetStrategy.rollingUpdate.maxUnavailable }}
{{- end -}}

{{- define "cg.creds.secret.name" -}}
{{-   $defaultSecretName := printf "%s-cp-cloudguard-creds" (include "name.prefix" .) -}}
{{-   printf "%s" (.Values.credentials.secretName | default $defaultSecretName) -}}
{{- end -}}

{{- /* extract multiple daemonset configurations if possible, otherwise, return the single one.
returns a dictionary of configurations
usage:
`{{- include "common.daemonset.config.extract.multiple" (dict "config" $config) -}}`
*/ -}}
{{- define "common.daemonset.config.extract.multiple" -}}
{{-   if empty .config.featureConfig.daemonConfigurationOverrides -}}
{{-     $_ := set .config "daemonConfigName" "daemon" -}}
{{-     dict "daemon" ( .config | toYaml ) | toYaml -}}
{{-   else -}}
{{-     $configs := dict -}}
{{-     $config := .config -}}
{{-     range $daemonConfigName, $currentConfiguration := $config.featureConfig.daemonConfigurationOverrides  -}}
{{-       $_ := required (printf "configuration %s must have nodeSelector field" $daemonConfigName ) (get $currentConfiguration "nodeSelector") -}}
{{-       $copyConfig:= deepCopy $config -}}
{{-       $copyAgentConfig:= deepCopy $config.agentConfig -}}
{{-       $mergedAgentConfig:= mergeOverwrite $copyAgentConfig $currentConfiguration -}}
{{-       if hasKey $currentConfiguration "platform" -}}
{{-         $platform := get $currentConfiguration "platform" -}}
{{-         include "validate.platform" $currentConfiguration -}}
{{-         $_ := set  $copyConfig "platform" ($platform | lower) -}}
{{-       end -}}
{{-       if hasKey $currentConfiguration "containerRuntime" -}}
{{-         $containerRuntime := get $currentConfiguration "containerRuntime" -}}
{{-         include "validate.container.runtime" $currentConfiguration -}}
{{-         $_ := set $copyConfig "containerRuntime" ($containerRuntime | lower) -}}
{{-       end -}}
{{-       $_ := set $mergedAgentConfig "env" ((concat (get $mergedAgentConfig "env") (get $copyAgentConfig "env") ) | uniq) -}}
{{-       $_ := set $copyConfig "agentConfig" $mergedAgentConfig -}}
{{-       $_ := set $copyConfig "daemonConfigName" ($daemonConfigName | lower) -}}
{{-       $_ := set $configs $daemonConfigName ($copyConfig | toYaml) -}}
{{-     end -}}
{{-     $configs | toYaml -}}
{{-   end -}}
{{- end -}}

{{- define "common.pod.properties.affinity" -}}
{{- if .agentConfig.affinity }}
{{-    .agentConfig.affinity | toYaml }}
{{- else }}
{{-   $allVirtualAffinities := (include "get.virtualNodesLabels" .) | fromYaml -}}
{{-   $nodeAffinityMatchExpressions := list (include "common.node.affinity.multiarch" . | fromYaml) -}}
{{-   if and (eq "DaemonSet" .resourceKind) (hasKey $allVirtualAffinities .platform) }}
{{-     $virtualNodesLabels := get $allVirtualAffinities .platform -}}
{{-     range $labelKey, $labelValue := $virtualNodesLabels -}}
{{-       $generatedExpression := dict "key" $labelKey "operator" "NotIn" "values" (list $labelValue) -}}
{{-       $nodeAffinityMatchExpressions = append $nodeAffinityMatchExpressions ( $generatedExpression ) -}}
{{-     end -}}
{{-   end -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
{{ $nodeAffinityMatchExpressions | toYaml | indent 10 }}
{{- /* add pod anti affinity */ -}}
{{-   if and (eq "Deployment" .resourceKind) (and (eq "enforcer" .agentName) (eq "admission" .featureName)) }}
{{      include "deployment.common.affinity.labels" . }}
{{-   end }}
{{- end -}}
{{- end -}}

{{- define "common.node.affinity.multiarch" -}}
key: kubernetes.io/arch
operator: In
values:
  - arm64
  - amd64
{{- end -}}

{{- /* virtual node labels, additions should keep the same format.
usage:
`{{- $virtualNodesLabels := get (include "get.virtualNodesLabels" . | fromYaml) .platform -}}`
*/ -}}
{{- define "get.virtualNodesLabels" -}}
eks:
  eks.amazonaws.com/compute-type: "fargate" 
# example_platform:
#   exampleLabelKey: "example_label_value"
{{- end -}}

{{- define "deployment.common.affinity.labels" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: "kubernetes.io/name"
              operator: In
              values:
                - {{ include "agent.resource.name" . }}
        topologyKey: "kubernetes.io/hostname"
{{- end -}}

{{- /* list of supported platforms
usage: 
`{{- $supportedPlatforms := (include "supported.platforms" .) | splitList " " -}}`
*/ -}}
{{- define "supported.platforms" -}}
kubernetes kubernetes.coreos tanzu openshift openshift.v3 eks eks.bottlerocket gke.cos gke.autopilot k3s rke2
{{- end -}}

{{- /* list of supported containter runtimes
usage: 
`{{- $supportedRuntimes := (include "supported.containerRuntimes" .) | splitList " " -}}`
*/ -}}
{{- define "supported.containerRuntimes" -}}
docker containerd cri-o
{{- end -}}

{{- /* value for annotations to change so resources are triggered again
usage: 
{{- include "annotations.sha256" $config -}}`
*/ -}}
{{- define "annotations.sha256" -}}
{{- if not (hasKey .Values "sha256annotations") -}}
{{- $sha256AnnotationsDict := dict -}}
{{- $_ := set $sha256AnnotationsDict "checksum/config" (include  (print .Template.BasePath "/cg-config.yaml") .  | sha256sum | trunc 63) -}}
{{- $_ := set $sha256AnnotationsDict "checksum/cgsecret" (include  (print .Template.BasePath "/cg-creds-secret.yaml") .  | sha256sum | trunc 63) -}}
{{- $_ := set $sha256AnnotationsDict "checksum/regsecret" (include  (print .Template.BasePath "/registry-creds-secret.yaml") .  | sha256sum | trunc 63) -}}
{{- $_ := set .Values "sha256annotations" $sha256AnnotationsDict -}}
{{- end -}}
{{- .Values.sha256annotations | toYaml -}}
{{- end -}}
