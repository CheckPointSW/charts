{{/* Parse cloudguardURL and create variables for specific parts of the URL */}}
{{- define "cloudguardURL_host" -}}
{{- ( include "dome9.url" . | urlParse ).host -}}
{{- end -}}

{{- define "cloudguardURL_path" -}}
{{- printf "%s/" (( include "dome9.url" . | urlParse ).path) -}}
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
{{ printf "%s-%s" $.Release.Name $agentFullName }}
{{- end -}}

{{- /* Service account name of a given agent (provided in values.yaml or auto-generated */ -}}
{{- define "agent.service.account.name" -}}
{{- default (include "agent.resource.name" .) .agentConfig.serviceAccountName }}
{{- end -}}

{{- /* Full path to the image of the main container of the provided agent */ -}}
{{- define "agent.main.image" -}}
{{- $tag := .agentConfig.tag }}
{{- if or .Values.debugImages .featureConfig.debugImages .agentConfig.debugImages }}
{{- $tag = printf "%s-debug" .agentConfig.tag }}
{{- end }}
{{- $image := printf "%s/%s:%s" .Values.imageRegistry.url .agentConfig.image $tag }}
{{- default $image .agentConfig.fullImage }}
{{- end -}}

{{- /* Full path to the image of a provided side-car container */ -}}
{{- define "agent.sidecar.image" -}}
{{- $containerConfig := get .agentConfig .containerName }}
{{- $tag := $containerConfig.tag }}
{{- if or .Values.debugImages .featureConfig.debugImages .agentConfig.debugImages $containerConfig.debugImage }}
{{- $tag = printf "%s-debug" $containerConfig.tag }}
{{- end }}
{{- $image := printf "%s/%s:%s" .Values.imageRegistry.url $containerConfig.image $tag }}
{{- default $image $containerConfig.fullImage }}
{{- end -}}

{{- /* Full path to the fluentbit image used in agent with provided config */ -}}
{{- define "agent.fluentbit.image" -}}
{{- $containerConfig := .agentConfig.fluentbit }}
{{- $image := printf "%s/%s:%s" .Values.imageRegistry.url $containerConfig.image $containerConfig.tag }}
{{- default $image $containerConfig.fullImage }}
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
agentVersion: {{ .agentConfig.tag }}
# seccomp.security.alpha.kubernetes.io/pod: {{ .Values.podAnnotations.seccomp }}
{{- if .Values.podAnnotations.apparmor }}
container.apparmor.security.beta.kubernetes.io/{{ template "agent.resource.name" . }}:
{{ toYaml .Values.podAnnotations.apparmor | indent 2 }}
{{- end }}
{{- end -}}

{{- /* Pod properties commonly used in agents */ -}}
{{- define "common.pod.properties" -}}
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
- name: {{ .Release.Name }}-regcred
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
      name: {{ .Release.Name }}-cp-cloudguard-configmap
      key: clusterID
- name: NAMESPACE_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName

{{- template "user.defined.env" . -}}

{{- if .Values.proxy }}
- name: HTTPS_PROXY
  value: "{{ .Values.proxy }}"
- name: NO_PROXY
  value: "kubernetes.default.svc"
{{- end -}}
{{- end -}}

{{- /* Environment variables needed for fluentbit-based side-cars */ -}}
{{- define "fluentbit.env" -}}
- name: CP_KUBERNETES_CLUSTER_ID
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-cp-cloudguard-configmap
      key: clusterID
- name: CP_KUBERNETES_DOME9_URL
  value: {{ template "cloudguardURL_host" . }}
- name: CP_KUBERNETES_USER
  valueFrom:
    secretKeyRef:
      name: {{ $.Release.Name }}-cp-cloudguard-creds
      key: username
- name: CP_KUBERNETES_PASS
  valueFrom:
    secretKeyRef:
        name: {{ $.Release.Name }}-cp-cloudguard-creds
        key: secret
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: TELEMETRY_VERSION
  value: {{ .Values.telemetryVersion }}
- name: POD_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.uid

{{- if .Values.proxy }}
- name: HTTP_PROXY
  value: "{{ .Values.proxy }}"
- name: NO_PROXY
  value: "kubernetes.default.svc"
{{- end -}}
{{- end -}}

{{- /* fluentbit http output parametes */ -}}
{{- define "fluentbit-http-output-param.conf" }}
Name            http
Format          json_lines
Host            ${CP_KUBERNETES_DOME9_URL}
Header          Kubernetes-Account  ${CP_KUBERNETES_CLUSTER_ID}
Header          Node-Name   ${NODE_NAME}
Header          Agent-Version   {{ .agentVersion }}
Compress        gzip
http_User       ${CP_KUBERNETES_USER}
http_Passwd     ${CP_KUBERNETES_PASS}
Port            443        
tls             On
tls.verify      On
{{- end -}}
 
{{- /* fluentbit configmap to send metric */ -}}
{{- define "fluentbit-metric.conf" -}}   
[SERVICE]
    Flush                      5
    Daemon                     Off
    Log_Level                  info
    storage.path               /tmp/fb-tmp
    storage.sync               normal
    storage.checksum           off
    storage.backlog.mem_limit  1M   
[INPUT]
    Name            exec
    Command         find {{ .metricPath }} -type f | xargs cat 
    Tag             metrics
    Buf_Size        8mb
    Mem_Buf_Limit   1mb
    Interval_Sec    300
    Interval_NSec   0
[INPUT]
    Name             tail
    Path             {{ .metricTailPath }}
    Tag              metrics
    Mem_Buf_Limit    1mb
    Refresh_Interval 3
    Read_from_Head   true
[OUTPUT]
    Match                     metrics
    Uri                       ${CP_KUBERNETES_METRIC_URI}
    Header          Pod-Id    ${POD_ID}
    Header          Telemetry-Version  ${TELEMETRY_VERSION}
    Retry_Limit               3
{{ include "fluentbit-http-output-param.conf" . | indent 4 }}
{{- end -}}

{{- /* fluentbit container for agents telemetry, do not use by agents sending alerts */ -}}
{{- define "telemetry.container" -}}
# fluentbit
- name: fluentbit
  image: {{ template "agent.fluentbit.image" . }}
  imagePullPolicy: {{ .Values.imagePullPolicy }} 
  securityContext:
    allowPrivilegeEscalation: false
  env:
{{ include "fluentbit.env" . | indent 2 }}
  - name: CP_KUBERNETES_METRIC_URI
    value: {{ template "cloudguardURL_path" . }}agenttelemetry
{{- if .agentConfig.fluentbit.resources }}
  resources:
{{ toYaml .agentConfig.fluentbit.resources | indent 4 }}
{{- end }}
  volumeMounts:
  - name: config-volume-fluentbit
    mountPath: /fluent-bit/etc/fluent-bit.conf
    subPath: fluent-bit.conf
  - name: metrics
    mountPath: /metric
  - name: metrics-tail
    mountPath: /metric-tail
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
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid datacenter: %s (should be one of: 'usea1' [default], 'euwe1', 'apse1', 'apse2', 'apso1')"  .Values.datacenter -}}
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

{{- define "cloudguard.nonroot.user" -}}
17112
{{- end }}

{{- define "validate.container.runtime" -}}
{{- if has .Values.containerRuntime (list "docker" "containerd") -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid containerRuntime: %s (should be one of: 'docker', 'containerd')"  .Values.containerRuntime -}}
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
{{/* examples for runtime version: docker://19.3.3, containerd://1.3.3 */}}
{{- $containerRuntimeVersion := (first $nodes.items).status.nodeInfo.containerRuntimeVersion }}
{{- $containerRuntime := first (regexSplit ":" $containerRuntimeVersion -1) }}
{{- if has $containerRuntime (list "docker" "containerd") -}}
{{- $containerRuntime }}
{{- else -}}
{{- $err := printf "\n\nERROR: Unsupported container runtime: %s" $containerRuntime -}}
{{- fail $err -}}
{{- end -}}
{{- else -}}
{{- fail "\n\nERROR: No nodes found, cannot identify container runtime. Use '--set containerRuntime=docker' or '--set containerRuntime=containerd'" -}}
{{- end -}}
{{- end -}}
{{- end -}}
