#  Check Point Cloudguard agents

## Introduction

This chart deploys the agents required by [Check Point CloudGuard](https://portal.checkpoint.com/) to provide Inventory Management, Posture Management, Image Assurance, Visibility, Threat Intelligence, Runtime Protection, Admission Control, and Monitoring capabilities.

Note: notice that some of the above capabilities require enrollment in the Early Availability program (contact a Check Point representative for more details).

## Prerequisites

General
- Kubernetes 1.12+, all nodes should have the same container runtime (docker, containerd or cri-o)
- Helm 3.0+
- Check Point CloudGuard account credentials

For the Admission Control feature
- Kubernetes 1.16+

For the Threat Intelligence feature
- Kernel 4.1+

For the Runtime Protection feature
- Kernel 4.14
- Kubernetes 1.16+


## Installing the Chart

To install the chart with the chosen release name (e.g. `my-release`), run:

```bash
$ helm repo add checkpoint https://raw.githubusercontent.com/CheckPointSW/charts/master/repository/
$ helm install my-release checkpoint/cloudguard --set credentials.user=[CloudGuard API Key] --set credentials.secret=[CloudGuard API Secret] --set clusterID=[Cluster ID] --namespace [Namespace] --create-namespace
```

These are the additional optional flags to enable add-ons:

```bash
$ 
$ --set addons.imageScan.enabled=true 
$ --set addons.flowLogs.enabled=true
$ --set addons.admissionControl.enabled=true
$ --set addons.runtimeProtection.enabled=true
```

This command deploys an invetory agent as well as optional add-on agents.

**Note**: the following add-ons require enrollment in the Early Availability program:
* Threat Intelligence (flowLogs)
* Runtime Protection (runtimeProtection)

> **Tip**: List all releases using `helm list --namespace [Namespace]`


## Upgrading the chart

To upgrade the deployment and/or to add/remove additional feature run:

```bash
$ helm repo update
$ helm upgrade my-release checkpoint-ea/cloudguard --set credentials.user=[CloudGuard API Key] --set credentials.secret=[CloudGuard API Secret] --set clusterID=[Cluster ID] --set addons.imageScan.enabled=[true/false] --set addons.flowLogs.enabled=[true/false] --namespace [Namespace]
```

## Uninstalling the Chart

To uninstall the `my-release` deployment:

```bash
$ helm uninstall my-release --namespace [Namespace]
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

In order to get the [Check Point CloudGuard](https://portal.checkpoint.com/) Cluster ID & credentials, you must first complete the Kubernetes Cluster onboarding process in [Check Point CloudGuard](https://portal.checkpoint.com/) website.

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and CloudGuard directives that map to environment variables.

Specify each parameter by adding `--set key=value[,key=value]` to the `helm install`. For example,

```bash
$ helm install my-release checkpoint/cloudguard --set varname=value
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release checkpoint/cloudguard -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

**Maximal image size for Image Assurance**

For Image Assurance feature the default maximal image size to scan is 2GB, and the relevant imageScan-engine pod memory limit is 2.5GB. In order to configure a different maximal image size, *addons.imageScan.maxImageSizeMb* parameter should be set with the maximal image size in MB. Pay attention, using this flag defines also the memory limit of imagescan-engine pod to this value + 500MB. E.g., to scan images of size of up to 3000MB, helm install command should be appended with:
```bash
     --set addons.imageScan.maxImageSizeMb=3000
```

It will define memory limit for *imagescan-engine* pod to be 3.5GB.

**Number of Image Assurance Scanners**

The number of Image Assurance scanners can be increased to add parallelism and reduce the time it takes to scan multiple images. By default there is one such scanner.
Modifying the number of Image Assurance scanners can be done by setting the addons.imageScan.engine.replicaCount parameter. E.g. to set the number of scanning pods to 2, helm install command should be appended with:
```bash
--set addons.imageScan.engine.replicaCount=2
```

Note that each additional scanner will require additional resources.

## Configurable parameters

The following table list the configurable parameters of this chart and their default values.

| Parameter                                                  | Description                                                     | Default                                          |
| ---------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------ |
| `clusterID`                                                | Cluster Unique identifier in CloudGuard system                  | `CHANGEME`                                       |
| `datacenter`                                               | CloudGuard datacenter (usea1, euwe1 apse1, apse2, apso1)        | `usea1`                                          |
| `credentials.secret`                                       | CloudGuard APISecret (Note: mandatory unless `credentials.secretName` is specified) | `CHANGEME`                                       |
| `credentials.user`                                         | CloudGuard APIID  (Note: mandatory unless `credentials.secretName` is specified) | `CHANGEME`                                       |
| `credentials.secretName`                                    | Name of an existing Kubernetes Secret that contains CloudGuard APIID (data.username) and APISecret (data.secret) | None                                       |
| `rbac.pspEnabled`                                          | Specifies whether PSP resources should be created               | `false`                                          |
| `imageRegistry.url`                                        | Image registry                                                  | `quay.io`                                        |
| `imageRegistry.authEnabled`                                | Whether or not Image Registry access is password-protected      | `true`                                           |
| `imageRegistry.user`                                       | Image registry username                                         | `CHANGEME`                                       |
| `imageRegistry.password`                                   | Image registry password                                         | `CHANGEME`                                       |
| `imagePullPolicy`                                          | Image pull policy                                               | `Always`                                         |
| `proxy`                                                    | Proxy settings (e.g. http://my-proxy.com:8080)                  | `{}`                                             |
| `containerRuntime`                                         | Container runtime (docker/containerd/cri-o) overriding auto-detection | ``                                         |
| `platform`                                                 | Kubernetes platform (kubernetes/tanzu/openshift/openshift.v3/eks.bottlerocket) overriding auto-detection | `kubernetes`                                |
| `seccompProfile`                                           | Computer Security facility profile. (to be used in kubernetes 1.19 and up) | `RuntimeDefault`                                |
| `podAnnotations.seccomp`                                   | Computer Security facility profile. (to be used in kubernetes below 1.19) | `runtime/default`                                |
| `podAnnotations.apparmor`                                  | Apparmor Linux kernel security module profile.                  | `{}`                                             |
| `priorityClassName`                                        | Specifies custom priorityClassName                              | ``                                               |
| `inventory.agent.image`                                    | Specify image for the agent                                     | `checkpoint/consec-inventory-agent`              |
| `inventory.agent.tag`                                      | Specify image tag for the agent                                 | `1.6.1`                                          |
| `inventory.agent.serviceAccountName`                       | Specify custom Service Account for the Inventory agent          | ``                                               |
| `inventory.agent.replicaCount`                             | Number of Inventory agent instances to be deployed              | `1`                                              |
| `inventory.agent.env`                                      | Additional environmental variables for Inventory agent          | `{}`                                             |
| `inventory.agent.resources`                                | Resources restriction (e.g. CPU, memory) for Inventory agent    | `{}`                                             |
| `inventory.agent.nodeSelector`                             | Node labels for pod assignment for Inventory agent              | `{}`                                             |
| `inventory.agent.tolerations`                              | List of node taints to tolerate for Inventory agent             | `[]`                                             |
| `inventory.agent.affinity`                                 | Affinity settings for Inventory agent                           | `{}`                                             |
| `inventory.priorityClassName`                              | Specifies custom priorityClassName                              | ``                                               |
| `addons.imageScan.enabled`                                 | Specifies whether the Image Scan addon should be installed      | `false`                                          |
| `addons.imageScan.priorityClassName`                       | Specifies custom priorityClassName                              | ``                                               |
| `addons.imageScan.maxImageSizeMb`                          | Specifies in MiBytes maximal image size to scan, its value + 500MB will be imageScan.engine main container memory limit | ``                                               |
| `addons.imageScan.daemon.image`                            | Specify image for the agent                                     | `checkpoint/consec-imagescan-daemon`             |
| `addons.imageScan.daemon.tag`                              | Specify image tag for the agent                                 |`2.15.0`                                           |
| `addons.imageScan.daemon.serviceAccountName`               | Specify custom Service Account for the agent                    | ``                                               |
| `addons.imageScan.daemon.env`                              | Additional environmental variables for the agent                | `{}`                                             |
| `addons.imageScan.daemon.resources`                        | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.daemon.nodeSelector`                     | Node labels for pod assignment                                  | `{}`                                             |
| `addons.imageScan.daemon.tolerations`                      | List of node taints to tolerate                                 | `operator: Exists`                               |
| `addons.imageScan.daemon.affinity`                         | Affinity setting                                                | `{}`                                             |
| `addons.imageScan.daemon.shim.image`                       | Specify image for the shim container                            | `checkpoint/consec-imagescan-shim`               |
| `addons.imageScan.daemon.shim.tag`                         | Specify image tag for the shim container                        |`2.15.0`                                           |
| `addons.imageScan.daemon.shim.env`                         | Additional environmental variables for the shim container       | `{}`                                             |
| `addons.imageScan.daemon.shim.resources`                   | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.engine.image`                            | Specify image for the agent                                     | `checkpoint/consec-imagescan-engine`             |
| `addons.imageScan.engine.tag`                              | Specify image tag for the agent                                 |`2.15.0`                                           |
| `addons.imageScan.engine.serviceAccountName`               | Specify custom Service Account for the agent                    | ``                                               |
| `addons.imageScan.engine.replicaCount`                     | Number of scanning engine instances to be deployed             		   | `1`                                              |
| `addons.imageScan.engine.env`                              | Additional environmental variables for the agent                | `{}`                                             |
| `addons.imageScan.engine.resources`                        | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.engine.nodeSelector`                     | Node labels for pod assignment                                  | `{}`                                             |
| `addons.imageScan.engine.tolerations`                      | List of node taints to tolerate                                 | `[]`                                             |
| `addons.imageScan.engine.affinity`                         | Affinity setting                                                | `{}`                                             |
| `addons.imageScan.list.image`                              | Specify image for the agent                                     | `checkpoint/consec-imagescan-engine`             |
| `addons.imageScan.list.tag`                                | Specify image tag for the agent                                 |`2.15.0`                                          |
| `addons.imageScan.list.serviceAccountName`                 | Specify custom Service Account for the agent                    | ``                                               |
| `addons.imageScan.list.env`                                | Additional environmental variables for the agent                | `{}`                                             |
| `addons.imageScan.list.resources`                          | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.list.nodeSelector`                       | Node labels for pod assignment                                  | `{}`                                             |
| `addons.imageScan.list.tolerations`                        | List of node taints to tolerate                                 | `[]`                                             |
| `addons.imageScan.list.affinity`                           | Affinity setting                                                | `{}`                                             |
| `addons.flowLogs.enabled`                                  | Specifies whether the Flow Logs addon should be installed       | `false`                                          |
| `addons.flowLogs.priorityClassName`                        | Specifies custom priorityClassName                              | ``                                               |
| `addons.flowLogs.daemon.image`                             | Specify image for the agent                                     | `checkpoint/consec-flowlogs-daemon`              |
| `addons.flowLogs.daemon.tag`                               | Specify image tag for the agent                                 |`0.7.0`                                           |
| `addons.flowLogs.daemon.serviceAccountName`                | Specify custom Service Account for the agent                    | ``                                               |
| `addons.flowLogs.daemon.logLevel`                          | What should be logged. (info, debug)                            | `info`                                           |
| `addons.flowLogs.daemon.env`                               | Additional environmental variables for the agent                | `{}`                                             |
| `addons.flowLogs.daemon.resources`                         | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.flowLogs.daemon.nodeSelector`                      | Node labels for pod assignment                                  | `{}`                                             |
| `addons.flowLogs.daemon.tolerations`                       | List of node taints to tolerate                                 | `operator: Exists`                               |
| `addons.flowLogs.daemon.affinity`                          | Affinity setting                                                | `{}`                                             |
| `addons.admissionControl.enabled`                          | Specify whether the Admission Control addon should be installed | `false`                                          |
| `addons.admissionControl.priorityClassName`                | Specifies custom priorityClassName                              | ``                                               |
| `addons.admissionControl.policy.image`                     | Specify image for the agent                                     | `checkpoint/consec-admission-policy`             |
| `addons.admissionControl.policy.tag`                       | Specify image tag for the agent                                 |`1.2.1`                                           |
| `addons.admissionControl.policy.serviceAccountName`        | Specify custom Service Account for the agent                    | ``                                               |
| `addons.admissionControl.policy.env`                       | Additional environmental variables for the agent                | `{}`                                             |
| `addons.admissionControl.policy.resources`                 | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.admissionControl.policy.nodeSelector`              | Node labels for pod assignment                                  | `{}`                                             |
| `addons.admissionControl.policy.tolerations`               | List of node taints to tolerate                                 | `[]`                                             |
| `addons.admissionControl.policy.affinity`                  | Affinity setting                                                | `{}`                                             |
| `addons.admissionControl.enforcer.image`                   | Specify image for the agent                                     | `checkpoint/consec-admission-enforcer`           |
| `addons.admissionControl.enforcer.tag`                     | Specify image tag for the agent                                 |`2.1.0`                                           |
| `addons.admissionControl.enforcer.serviceAccountName`      | Specify custom Service Account for the agent                    | ``                                               |
| `addons.admissionControl.enforcer.replicaCount`            | Number of Inventory agent instances to be deployed              | `2`                                              |
| `addons.admissionControl.enforcer.env`                     | Additional environmental variables for the agent                | `{}`                                             |
| `addons.admissionControl.enforcer.failurePolicyIntervalHours`| If the agent is unable to synchronize it's policy, this is the number of hours it will wait before switching to a fail-open policy | `24`                                             |
| `addons.admissionControl.enforcer.resources`               | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.admissionControl.enforcer.nodeSelector`            | Node labels for pod assignment                                  | `{}`                                             |
| `addons.admissionControl.enforcer.tolerations`             | List of node taints to tolerate                                 | `[]`                                             |
| `addons.admissionControl.enforcer.affinity`                | Affinity setting                                                | `{}`                                             |
| `addons.runtimeProtection.enabled`                         | Specifies whether the Runtime Protection addon should be installed | `false`                                          |
| `addons.runtimeProtection.priorityClassName`               | Specifies custom priorityClassName                              | ``                                               |
| `addons.runtimeProtection.daemon.image`                    | Specify image for the agent                                     | `checkpoint/consec-runtime-daemon`               |
| `addons.runtimeProtection.daemon.tag`                      | Specify image tag for the agent                                 |`0.0.812`                                         |
| `addons.runtimeProtection.daemon.serviceAccountName`       | Specify custom Service Account for the agent                    | ``                                               |
| `addons.runtimeProtection.daemon.env`                      | Additional environmental variables for the agent                | `{}`                                             |
| `addons.runtimeProtection.daemon.resources`                | Resources restriction (e.g. CPU, memory)                        | `requests.cpu: 100m`                             |
|                                                            |                                                                 | `requests.memory: 250Mi`                         |
|                                                            |                                                                 | `limits.cpu: 2000m`                              |
|                                                            |                                                                 | `limits.memory: 1Gi`                             |
| `addons.runtimeProtection.daemon.probe.image`              | Specify image for the agent                                     | `checkpoint/consec-runtime-probe`                |
| `addons.runtimeProtection.daemon.probe.tag`                | Specify image tag for the agent                                 |`0.28.0-cp-6`                                       |
| `addons.runtimeProtection.daemon.probe.resources`          | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.runtimeProtection.daemon.fluentbit.image`          | Specify image for the agent                                     | `checkpoint/consec-fluentbit`                    |
| `addons.runtimeProtection.daemon.fluentbit.tag`            | Specify image tag for the agent                                 |`1.6.9-cp`                                        |
| `addons.runtimeProtection.daemon.fluentbit.resources`      | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.runtimeProtection.daemon.nodeSelector`             | Node labels for pod assignment                                  | `beta.kubernetes.io/os: linux `                  |
| `addons.runtimeProtection.daemon.tolerations`              | List of node taints to tolerate                                 | `operator: Exists`                               |
| `addons.runtimeProtection.daemon.affinity`                 | Affinity setting                                                | `{}`                                             |
| `addons.runtimeProtection.policy.image`                    | Specify image for the agent                                     | `checkpoint/consec-runtime-policy`               |
| `addons.runtimeProtection.policy.tag`                      | Specify image tag for the agent                                 |`1.2.0`                                           |
| `addons.runtimeProtection.policy.serviceAccountName`       | Specify custom Service Account for the agent                    | ``                                               |
| `addons.runtimeProtection.policy.env`                      | Additional environmental variables for the agent                | `{}`                                             |
| `addons.runtimeProtection.policy.resources`                | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.runtimeProtection.policy.nodeSelector`             | Node labels for pod assignment                                  | `{}`                                             |
| `addons.runtimeProtection.policy.tolerations`              | List of node taints to tolerate                                 | `[]`                                             |
| `addons.runtimeProtection.policy.affinity`                 | Affinity setting                                                | `{}`                                             |
