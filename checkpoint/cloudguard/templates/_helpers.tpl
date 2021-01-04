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
{{- $image := printf "%s/%s:%s" .Values.imageRegistry.url .agentConfig.image .agentConfig.tag }}
{{- default $image .agentConfig.fullImage }}
{{- end -}}

{{- /* Full path to the image of a provided side-car container */ -}}
{{- define "agent.sidecar.image" -}}
{{- $containerConfig := get .agentConfig .containerName }}
{{- $image := printf "%s/%s:%s" .Values.imageRegistry.url $containerConfig.image $containerConfig.tag }}
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
seccomp.security.alpha.kubernetes.io/pod: {{ .Values.podAnnotations.seccomp }}
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

{{- /* Environment variables needed for fluentd-based side-cars */ -}}
{{- define "fluentd.env" -}}
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
  Return backend URL
*/}}
{{- define "dome9.url" -}}
{{- if $.Values.cloudguardURL -}}
{{- printf "%s" $.Values.cloudguardURL -}}
{{- else -}}
{{- $region := lower $.Values.region -}}
{{- if has $region (list "us" "us1") -}}
{{- printf "https://api-cpx.dome9.com" -}}
{{- else if has $region (list "eu1" "ap1") -}}
{{- printf "https://api-cpx.%s.dome9.com" $region -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid region: %s (should be one of: 'us1' [default], 'eu1', 'ap1')"  .Values.region -}}
{{- fail $err -}}
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