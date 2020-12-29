#  Check Point Cloudguard agents

## Introduction

This chart creates a single resource management Pod that scans the cluster's resources (Nodes, Images, Pods, Namespaces, Services, PSP, Network Policy, Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount, and Ingress) and uploads their meta-data to [Check Point ClougGuard](https://secure.dome9.com/).
Check Point ClougGuard provides Posture Management, Image Assurance, Visibility, Monitoring and Threat Hunting capabilities.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.0+
- A Check Point ClougGuard account and API key

## Installing the Chart

To install the chart with the chosen release name (e.g. `my-release`), run:

```bash
$ helm repo add checkpoint-ea https://raw.githubusercontent.com/CheckPointSW/charts/ea/repository/
$ helm install asset-mgmt checkpoint-ea/cp-resource-management --set-string credentials.user=[CloudGuard API Key] --set-string credentials.secret=[CloudGuard API Secret] --set-string clusterID=[Cluster ID] --namespace=[Namespace] --create-namespace
```

These are the additional optional flags to enable add-ons:

```bash
$ 
$ --set addons.imageScan.enabled=true 
```

This command deploys a CloudGuard Resource Management agent as well as optional add-ons.


> **Tip**: List all releases using `helm list`


## Upgrading the chart

To upgrade the deployment and/or to add/remove additional feature run:

```bash
$ helm repo update
$ helm upgrade asset-mgmt checkpoint-ea/cp-resource-management --set-string credentials.user=[CloudGuard API Key] --set-string credentials.secret=[CloudGuard API Secret] --set-string clusterID=[Cluster ID] --set addons.imageScan.enabled=[true/false] --set addons.flowLogs.enabled=[true/false] --namespace=[Namespace]
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

In order to get the [Check Point ClougGuard](https://secure.dome9.com/) Cluster ID & credentials, you must first complete the Kubernetes Cluster onboarding process in [Check Point ClougGuard](https://secure.dome9.com/) website.

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and CloudGuard directives that map to environment variables.

Specify each parameter using `--set key=value[,key=value]` or `--set-string key=value[,key=value]` to `helm install`. For example,

```bash
$ helm install my-release --set varname=true --set-string varname="string" checkpoint/cp-resource-management
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release -f values.yaml checkpoint/cp-resource-management
```

> **Tip**: You can use the default [values.yaml](values.yaml)

The following tables list the configurable parameters of this chart and their default values.

| Parameter                                                  | Description                                                     | Default                                          |
| ---------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------ |
| `clusterID`                                                | Cluster Unique identifier in CloudGuard system                  | `CHANGEME`                                       |
| `region`                                                   | CloudGuard region (US, EU or AP)                                | `US`                                             |
| `credentials.secret`                                       | CloudGuard APISecret                                            | `CHANGEME`                                       |
| `credentials.user`                                         | CloudGuard APIID                                                | `CHANGEME`                                       |
| `imagePullPolicy`                                          | Image pull policy                                               | `IfNotPresent`                                   |
| `imageRegistryCredendtialsSecretName`                      | Name of the Secret containing image registry access credentials | ``                                               |
| `proxy`                                                    | Proxy settings (e.g. http://my-proxy.com:8080)                  | `{}`                                             |
| `rbac.pspEnabled`                                          | Specifies whether PSP resources should be created               | `false`                                          |
| `podAnnotations`                                           | Common non-identifying metadata                                 | `{}`                                             |
| `inventory.agent.version`                                  | Inventory Agent version                                         | ``                                               |
| `inventory.agent.image`                                    | Specify custom image for Inventory agent                        | ``                                               |
| `inventory.agent.serviceAccountName`                       | Specify custom Service Account for the Inventory agent          | ``                                               |
| `inventory.agent.replicaCount`                             | Number of Inventory agent instances to be deployed              | `1`                                              |
| `inventory.agent.env`                                      | Additional environmental variables for Inventory agent          | `{}`                                             |
| `inventory.agent.resources`                                | Resources restriction (e.g. CPU, memory) for Inventory agent    | `{}`                                             |
| `inventory.agent.nodeSelector`                             | Node labels for pod assignment for Inventory agent              | `{}`                                             |
| `inventory.agent.tolerations`                              | List of node taints to tolerate for Inventory agent             | `[]`                                             |
| `inventory.agent.affinity`                                 | Affinity settings for Inventory agent                           | `{}`                                             |
| `addons.imageScan.enabled`                                 | Specifies whether the Image Scan addon should be installed      | `false`                                          |
| `addons.imageScan.daemon.version`                          | Agent version                                                   | ``                                               |
| `addons.imageScan.daemon.image`                            | Specify custom image for the agent                              | ``                                               |
| `addons.imageScan.daemon.serviceAccountName`               | Specify custom Service Account for the agent                    | ``                                               |
| `addons.imageScan.daemon.env`                              | Additional environmental variables for the agent                | `{}`                                             |
| `addons.imageScan.daemon.resources`                        | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.daemon.nodeSelector`                     | Node labels for pod assignment                                  | `{}`                                             |
| `addons.imageScan.daemon.tolerations`                      | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.imageScan.daemon.affinity`                         | Affinity setting                                                | `{}`                                             |
| `addons.imageScan.engine.version`                          | Agent version                                                   | ``                                               |
| `addons.imageScan.engine.image`                            | Specify custom image for the agent                              | ``                                               |
| `addons.imageScan.engine.serviceAccountName`               | Specify custom Service Account for the agent                    | ``                                               |
| `addons.imageScan.engine.env`                              | Additional environmental variables for the agent                | `{}`                                             |
| `addons.imageScan.engine.resources`                        | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.imageScan.engine.nodeSelector`                     | Node labels for pod assignment                                  | `{}`                                             |
| `addons.imageScan.engine.tolerations`                      | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.imageScan.engine.affinity`                         | Affinity setting                                                | `{}`                                             |
| `addons.flowLogs.enabled`                                  | Specifies whether the Flow Logs addon should be installed       | `false`                                          |
| `addons.flowLogs.daemon.version`                           | Agent version                                                   | ``                                               |
| `addons.flowLogs.daemon.image`                             | Specify custom image for the agent                              | ``                                               |
| `addons.flowLogs.daemon.serviceAccountName`                | Specify custom Service Account for the agent                    | ``                                               |
| `addons.flowLogs.daemon.env`                               | Additional environmental variables for the agent                | `{}`                                             |
| `addons.flowLogs.daemon.resources`                         | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.flowLogs.daemon.nodeSelector`                      | Node labels for pod assignment                                  | `{}`                                             |
| `addons.flowLogs.daemon.tolerations`                       | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.flowLogs.daemon.affinity`                          | Affinity setting                                                | `{}`                                             |
| `addons.runtimeProtection.enabled`                         | Specifies whether the Runtime Protection addon should be installed      | `false`                                          |
| `addons.runtimeProtection.policy.version`                  | Agent version                                                   | ``                                               |
| `addons.runtimeProtection.policy.image`                    | Specify custom image for the agent                              | ``                                               |
| `addons.runtimeProtection.policy.serviceAccountName`       | Specify custom Service Account for the agent                    | ``                                               |
| `addons.runtimeProtection.policy.env`                      | Additional environmental variables for the agent                | `{}`                                             |
| `addons.runtimeProtection.policy.resources`                | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.runtimeProtection.policy.nodeSelector`             | Node labels for pod assignment                                  | `{}`                                             |
| `addons.runtimeProtection.policy.tolerations`              | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.runtimeProtection.policy.affinity`                 | Affinity setting                                                | `{}`                                             |
| `addons.runtimeProtection.daemon.version`                  | Agent version                                                   | ``                                               |
| `addons.runtimeProtection.daemon.image`                    | Specify custom image for the agent                              | ``                                               |
| `addons.runtimeProtection.daemon.serviceAccountName`       | Specify custom Service Account for the agent                    | ``                                               |
| `addons.runtimeProtection.daemon.env`                      | Additional environmental variables for the agent                | `{}`                                             |
| `addons.runtimeProtection.daemon.resources`                | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.runtimeProtection.daemon.nodeSelector`             | Node labels for pod assignment                                  | `{}`                                             |
| `addons.runtimeProtection.daemon.tolerations`              | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.runtimeProtection.daemon.affinity`                 | Affinity setting                                                | `{}`                                             |
| `addons.admissionControl.enabled`                          | Specify whether the Admission Control addon should be installed | `false`                                          |
| `addons.admissionControl.policy.version`                   | Agent version                                                   | ``                                               |
| `addons.admissionControl.policy.image`                     | Specify custom image for the agent                              | ``                                               |
| `addons.admissionControl.policy.serviceAccountName`        | Specify custom Service Account for the agent                    | ``                                               |
| `addons.admissionControl.policy.env`                       | Additional environmental variables for the agent                | `{}`                                             |
| `addons.admissionControl.policy.resources`                 | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.admissionControl.policy.nodeSelector`              | Node labels for pod assignment                                  | `{}`                                             |
| `addons.admissionControl.policy.tolerations`               | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.admissionControl.policy.affinity`                  | Affinity setting                                                | `{}`                                             |
| `addons.admissionControl.enforcer.version`                 | Agent version                                                   | ``                                               |
| `addons.admissionControl.enforcer.image`                   | Specify custom image for the agent                              | ``                                               |
| `addons.admissionControl.enforcer.serviceAccountName`      | Specify custom Service Account for the agent                    | ``                                               |
| `addons.admissionControl.enforcer.env`                     | Additional environmental variables for the agent                | `{}`                                             |
| `addons.admissionControl.enforcer.resources`               | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `addons.admissionControl.enforcer.nodeSelector`            | Node labels for pod assignment                                  | `{}`                                             |
| `addons.admissionControl.enforcer.tolerations`             | List of node taints to tolerate                                 | `key: node-role.kubernetes.io/master`            |
|                                                            |                                                                 | `effect: NoSchedule`                             |
| `addons.admissionControl.enforcer.affinity`                | Affinity setting                                                | `{}`                                             |
