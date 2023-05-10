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
{{-   if eq "gke.autopilot" ( include "get.platform" .) -}}
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

{{- /* Service account name of a given agent (provided in values.yaml or auto-generated */ -}}
{{- define "agent.service.account.name" -}}
{{- default (include "agent.resource.name" .) .agentConfig.serviceAccountName }}
{{- end -}}

{{- /* Full path to the image of the main container of the provided agent. in case of autoUpgrade enabled we use the version without the patch */ -}}
{{- define "agent.main.image" -}}
{{-     $tag := .agentConfig.tag }}
{{-     if or .Values.debugImages .featureConfig.debugImages .agentConfig.debugImages }}
{{-         $tag = printf "%s-debug" .agentConfig.tag }}
{{-     end }}
{{-     if and (eq (include "get.autoUpgrade" .) "true") (regexMatch "^\\d+.\\d+.\\d+$" $tag) (ne .agentConfig.image "checkpoint/consec-runtime-daemon") -}}
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
{{-     if and (eq (include "get.autoUpgrade" .) "true") (regexMatch "^\\d+.\\d+.\\d+$" $tag) (ne .agentConfig.image "checkpoint/consec-runtime-probe") -}}
{{-         $tag = regexFind "\\d+.\\d+" $tag }}
{{-     end -}}
{{-     $image := printf "%s/%s:%s" .Values.imageRegistry.url $containerConfig.image $tag }}
{{-     default $image $containerConfig.fullImage }}
{{- end -}}

{{- /* Labels commonly used in our k8s resources */ -}}
{{- define "common.labels" -}}
app.kubernetes.io/name: {{ template "agent.resource.name" . }}
app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end -}}

{{- /* Labels commonly used in our "pod group" resources */ -}}
{{- define "common.labels.with.chart" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.name .Chart.version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ template "common.labels" . }}
{{- end -}}

{{- /* Pod annotations commonly used in agents */ -}}
{{- define "common.pod.annotations" -}}
{{- /* Openshift does not allow seccomp - So we don't add seccomp in openshift case */ -}}
{{- /* From k8s 1.19 and up we use the seccomp in securityContext so no need for it here, in case of template we don't know the version so we fall back to annotation */ -}}
{{- if and (not (contains "openshift" (include "get.platform" .))) (semverCompare "<1.19-0" .Capabilities.KubeVersion.Version ) }}
seccomp.security.alpha.kubernetes.io/pod: {{ .Values.podAnnotations.seccomp }}
{{- end }}
{{- if .Values.podAnnotations.apparmor }}
container.apparmor.security.beta.kubernetes.io/{{ template "agent.resource.name" . }}:
{{ toYaml .Values.podAnnotations.apparmor | indent 2 }}
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
{{- end }}
{{- if not (contains "openshift" (include "get.platform" .)) }}
securityContext:
  runAsUser: {{ include "cloudguard.nonroot.user" . }}
  runAsGroup: {{ include "cloudguard.nonroot.user" . }}
{{- if (semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version) }}
  seccompProfile:
{{ toYaml .Values.seccompProfile | indent 4 }}
{{- end }}
{{- end }}
serviceAccountName: {{ template "agent.service.account.name" . }}
{{- if .agentConfig.nodeSelector }}
nodeSelector:
{{ toYaml .agentConfig.nodeSelector | indent 2 }}
{{- end }}
{{- if .agentConfig.affinity }}
affinity:
{{ toYaml .agentConfig.affinity | indent 2 }}
{{- end }}
{{- if .agentConfig.tolerations }}
tolerations:
{{ toYaml .agentConfig.tolerations | indent 2 }}
{{- end }}
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
  value: {{ include "get.platform" . }}
{{- if eq (include "get.autoUpgrade" .) "true" }}
- name: AUTO_UPGRADE_ENABLED
  value: "true"
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
{{- end }}

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
{{- define "dockerconfigjson.b64enc" }}
    {{- $err := "Must disable .imageRegistry.authEnabled or specify .imageRegistry.user and .password" -}}
    {{- $user := required $err .Values.imageRegistry.user -}}
    {{- $pass := required $err .Values.imageRegistry.password -}}
    {{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .Values.imageRegistry.url (printf "%s:%s" $user $pass | b64enc) | b64enc }}
{{- end }}

{{- define "validate.container.runtime" -}}
{{- if has .Values.containerRuntime (list "docker" "containerd" "cri-o") -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid containerRuntime: %s (should be one of: 'docker', 'containerd', 'cri-o')"  .Values.containerRuntime -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{/*
  Construct "root" context (dict) from defaults.yaml included in the chart and the effective .Values of the release (overriding defaults)
*/}}
{{- define "get.root" -}}
{{- $defaults := (.Files.Get "defaults.yaml" | fromYaml ) }}
{{- $merged := deepCopy . | mustMergeOverwrite (dict "Values" $defaults) | toYaml }}
{{- $merged }}
{{- end -}}


{{- define "get.container.runtime" -}}
{{- if .Values.containerRuntime -}}
{{- include "validate.container.runtime" . -}}
{{- .Values.containerRuntime -}}
{{- else -}}
{{- $nodes := lookup "v1" "Node" "" "" -}}
{{- if ne (len $nodes) 0 -}}
{{/* examples for runtime version: docker://19.3.3, containerd://1.3.3, cri-o://1.20.3 */}}
{{- $containerRuntimeVersion := (first $nodes.items).status.nodeInfo.containerRuntimeVersion }}
{{- $containerRuntime := first (regexSplit ":" $containerRuntimeVersion -1) }}
{{- if has $containerRuntime (list "docker" "containerd" "cri-o") -}}
{{- $containerRuntime }}
{{- else -}}
{{- $err := printf "\n\nERROR: Unsupported container runtime: %s" $containerRuntime -}}
{{- fail $err -}}
{{- end -}}
{{- else -}}
{{- fail "\n\nERROR: No nodes found, cannot identify container runtime. Use '--set containerRuntime=docker' or '--set containerRuntime=containerd' or '--set containerRuntime=cri-o'" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "get.platform" -}}
{{-   if (include "is.helm.template.command" .) -}}
{{-     include "validate.platform" . -}}
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
{{-     $nodes := lookup "v1" "Node" "" "" -}}
{{/*
        nodeInfo.osImage example values:
        - "Bottlerocket OS 1.7.2 (aws-k8s-1.21)"
        - "Container-Optimized OS from Google"
*/}}
{{-     $firstNode :=  (first $nodes.items) -}}
{{-     $osImage := $firstNode.status.nodeInfo.osImage }}
{{-     if contains "Bottlerocket" $osImage -}}
{{-       printf "eks.bottlerocket" -}}
{{-     else if contains "Container-Optimized" $osImage -}}
{{-       printf "gke.cos" -}}
{{-     else if hasKey $firstNode.metadata.annotations "k3s.io/hostname"  -}}
{{-       printf "k3s" -}}
{{-     else if or (hasKey $firstNode.metadata.labels "eks.amazonaws.com/nodegroup") (hasKey $firstNode.metadata.labels "alpha.eksctl.io/nodegroup-name")  -}}
{{-       printf "eks" -}}
{{-     else -}}
{{-       include "validate.platform" . -}}
{{-       lower .Values.platform -}}
{{-     end -}}
{{-   end -}}
{{- end -}}


{{/*
if registry is not quay do not enable auto upgrade
 */}}
{{- define "get.autoUpgrade" -}}
{{-   if ne .Values.imageRegistry.url "quay.io" -}}
{{-     printf "false" -}}
{{-   else -}}
{{-     printf (.Values.autoUpgrade | toString) -}}
{{-   end -}}
{{- end -}}


{{/*
  use to know if we run from template (which mean wo have no connection to the cluster and cannot check Capabilities/nodes etc.)
  if there is no namespace probably we are running template
*/}}
{{- define "is.helm.template.command" -}}
{{- $namespace := lookup "v1" "Namespace" "" "" -}}
{{- if eq (len $namespace) 0 -}}
true
{{- end -}}
{{- end -}}

{{- define "containerd.sock.path" -}}
{{-   if .Values.containerRuntimeSocket -}}
{{/*    container runtime socket path validation: should contain '/run/' substring and end with '.sock' */}}
{{-     if or (not (contains "/run" .Values.containerRuntimeSocket)) (not (hasSuffix ".sock" .Values.containerRuntimeSocket)) -}}
{{-       $err := printf "\n\nERROR: Invalid container runtime socket path: '%s' (should contain '/run' substring and end with '.sock'.)"  .Values.containerRuntimeSocket -}}
{{-       fail $err -}} 
{{-     end -}}
{{      printf (.Values.containerRuntimeSocket | toString) }}
{{-   else if eq (include "get.platform" .) "eks.bottlerocket" -}}
{{-     printf "/run/dockershim.sock" -}}
{{-   else if eq (include "get.platform" .) "k3s" -}}
{{-     printf "/run/k3s/containerd/containerd.sock" -}}
{{-   else -}}
{{-     printf "/run/containerd/containerd.sock" -}}
{{-   end -}}
{{- end -}}

{{- define "validate.platform" -}}
{{- if has .Values.platform (list "kubernetes" "tanzu" "openshift" "openshift.v3" "eks" "eks.bottlerocket" "gke.cos" "gke.autopilot" "k3s") -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid platform: %s (should be one of: 'kubernetes', 'tanzu', 'openshift', 'openshift.v3', 'eks', 'eks.bottlerocket', 'gke.cos', 'gke.autopilot', 'k3s')"  .Values.platform -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}

{{- define "daemonset.updateStrategy" -}}
updateStrategy:
  rollingUpdate:
    maxUnavailable: {{ .Values.daemonSetStrategy.rollingUpdate.maxUnavailable }}
{{- end -}}

{{- define "cg.creds.secret.name" -}}
{{-   $defaultSecretName := printf "%s-cp-cloudguard-creds" (include "name.prefix" .) }}
{{-   printf "%s" (.Values.credentials.secretName | default $defaultSecretName) -}}
{{- end -}}
