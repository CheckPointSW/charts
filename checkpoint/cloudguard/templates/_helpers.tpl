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
{{- $defaultImage := printf "%s/consec-%s-%s:%s" .Values.imageRegistry .featureName .agentName .agentConfig.version }}
{{- default $defaultImage .agentConfig.image }}
{{- end -}}

{{- /* Full path to the image of a provided side-car container */ -}}
{{- define "agent.sidecar.image" -}}
{{- $containerConfig := get .agentConfig .containerName }}
{{- $defaultImage := printf "%s/consec-%s-%s:%s" .Values.imageRegistry .featureName .containerName $containerConfig.version }}
{{- default $defaultImage $containerConfig.image }}
{{- end -}}

{{- /* Full path to the fluentbit image used in agent with provided config */ -}}
{{- define "agent.fluentbit.image" -}}
{{- $containerConfig := .agentConfig.fluentbit }}
{{- $defaultImage := printf "%s/consec-fluentbit:%s" .Values.imageRegistry $containerConfig.version }}
{{- default $defaultImage $containerConfig.image }}
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
agentVersion: {{ .agentConfig.version }}
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
imagePullSecrets:
- name: {{ required "imageRegistryCredendtialsSecretName is required -- the name of the Secret containing image registry access credentials." .Values.imageRegistryCredendtialsSecretName }}
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

{{- define "dome9.url" -}}
{{- if $.Values.cloudguardURL -}}
{{- printf "%s" $.Values.cloudguardURL -}}
{{- else -}}
{{- $region := default "us1" (lower $.Values.region) -}}
{{- if has $region (list "us1" "us") -}}
{{- printf "https://api-cpx.dome9.com" -}}
{{- else if has $region (list "eu1" "eu") -}}
{{- printf "https://api-cpx.eu1.dome9.com" -}}
{{- else if has $region (list "ap1" "ap") -}}
{{- printf "https://api-cpx.ap1.dome9.com" -}}
{{- else -}}
{{- $err := printf "\n\nERROR: Invalid region: %s (should be one of: 'US' [default], 'EU', 'AP')"  .Values.region -}}
{{- fail $err -}}
{{- end -}}
{{- end -}}
{{- end -}}