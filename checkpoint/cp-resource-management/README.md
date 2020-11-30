#  Check Point Cloudguard Dome9 agents

## Introduction

This chart creates a single resource management Pod that scans the cluster's resources (Nodes, Images, Pods, Namespaces, Services, PSP, Network Policy, and Ingress) and uploads them to [Check Point ClougGuard Dome9](https://secure.dome9.com/).
Check Point ClougGuard Dome9 provides Compliance, Visibility, Monitoring and Threat Hunting capabilities.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.0+
- A Check Point ClougGuard Dome9 account and API key

## Installing the Chart

To install the chart with the chosen release name (e.g. `my-release`), run:

```bash
$ helm repo add checkpoint https://raw.githubusercontent.com/CheckPointSW/charts/master/repository/
$ helm install asset-mgmt checkpoint/cp-resource-management --set-string credentials.user=[CloudGuard Dome9 API Key] --set-string credentials.secret=[CloudGuard Dome9 API Secret] --set-string clusterID=[Dome9 Cluster ID] --namespace=[Namespace] --create-namespace
```

This command deploys a Dome9 Resource Management agent.

> **Tip**: List all releases using `helm list`

## Upgrading the chart

To upgrade the deployment and/or to add/remove additional feature run:

```bash
$ helm repo update
$ helm upgrade asset-mgmt checkpoint/cp-resource-management --set-string credentials.user=[CloudGuard API Key] --set-string credentials.secret=[CloudGuard API Secret] --set-string clusterID=[Cluster ID] --namespace=[Namespace]
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

In order to get the [Check Point ClougGuard Dome9](https://secure.dome9.com/) Cluster ID & credentials, you must first complete the Kubernetes Cluster onboarding process in [Check Point ClougGuard Dome9](https://secure.dome9.com/) website.

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and Dome9 directives that map to environment variables.

Specify each parameter to `helm install` using `--set key=value[,key=value]` or `--set-string key=value[,key=value]`. For example,

```bash
$ helm install asset-mgmt --set varname=true --set-string varname="string" checkpoint/cp-resource-management
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release -f values.yaml checkpoint/cp-resource-management
```

> **Tip**: You can use the default [values.yaml](values.yaml)

The following tables list the configurable parameters of this chart and their default values.

| Parameter                                                  | Description                                                     | Default                                          |
| ---------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------ |
| `replicaCount`                                             | Number of agent instances to deployed                           | `1`                                              |
| `rbac.create`                                              | Specifies whether RBAC resources should be created              | `true`                                           |
| `rbac.pspEnabled`                                          | Specifies whether PSP resources should be created               | `false`                                          |
| `serviceAccount.create`                                    | Specifies whether RBAC resources should be created              | `true`                                           |
| `serviceAccount.name`                                      | Specifies whether RBAC resources should be created              | ``                                               |
| `image.repository`                                         | Agent image                                                     | `quay.io/checkpoint/cp-resource-management`      |
| `image.tag`                                                | Image version                                                   | `{TAG_NAME}`                                     |
| `image.pullPolicy`                                         | Image pull policy                                               | `IfNotPresent`                                   |
| `env`                                                      | Additional environmental variables                              | `{}`                                             |
| `credentials.secret`                                       | CloudGuard Dome9 APISecret                                      | `CHANGEME`                                       |
| `credentials.user`                                         | CloudGuard Dome9 APIID                                          | `CHANGEME`                                       |
| `clusterID`                                                | Cluster Unique identifier in CloudGuard system                  | `CHANGEME`                                       |
| `resources`                                                | Resources restriction (e.g. CPU, memory)                        | `{}`                                             |
| `podAnnotations`                                           | Arbitrary non-identifying metadata                              | `{}`                                             |
| `nodeSelector`                                             | Node labels for pod assignment                                  | `{}`                                             |
| `tolerations`                                              | List of node taints to tolerate                                 | `[]`                                             |
| `affinity`                                                 | Affinity settings                                               | `{}`                                             |
| `proxy`                                                    | Proxy settings (e.g. http://my-proxy.com:8080)                  | `{}`                                             |
