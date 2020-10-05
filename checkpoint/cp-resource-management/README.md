#  Dome9 asset management agent

## Introduction

This chart creates a single resource management Pod that scans the cluster's resources (Pods, Services, Nodes, PSP, Network Policy, and Ingress) and uploads them to [Dome9](https://secure.dome9.com/).
Dome9 provides compliance, Visibility, Monitoring and Threat Hunting capabilities.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.0+
- A Dome9 account and API key

## Installing the Chart

To install the chart with the chosen release name (e.g. `my-release`), run:

```bash
$ helm repo add checkpoint https://raw.githubusercontent.com/CheckPointSW/charts/master/repository/
$ helm install my-release checkpoint/cp-resource-management --set-string credentials.user=[Dome9 API Key] --set-string credentials.secret=[Dome9 API Secret] --set-string clusterID=[Dome9 Cluster ID]
```

This command deploys a Dome9 Resource Management agent.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

In order to get the [Dome9](https://secure.dome9.com/) Cluster ID & credentials you must first complete the Kubernetes Cluster onboarding process in [Dome9](https://secure.dome9.com/) website.

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and Dome9 directives that map to environment variables.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install my-release --set varname=true checkpoint/cp-resource-management
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release -f values.yaml checkpoint/cp-resource-management
```

> **Tip**: You can use the default [values.yaml](values.yaml)

The following tables list the configurable parameters of this chart and their default values.

| Parameter                                         | Description                                                   | Default                                                     |
| ------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- |
| `replicaCount`                                    | Number of provisioner instances to deployed                   | `1`                                                         |
| `RBAC.create`                                     | Specifies whether RBAC resources should be created            | `true`                                                      |
| `serviceAccount.create`                           | Specifies whether RBAC resources should be created            | `true`                                                      |
| `serviceAccount.name`                             | Specifies whether RBAC resources should be created            | ``                                                          |
| `image.repository`                                | Provisioner image                                             | `quay.io/checkpoint/cp-resource-management`                 |
| `image.tag`                                       | Version of provisioner image                                  | `{TAG_NAME}`                                                |
| `image.pullPolicy`                                | Image pull policy                                             | `IfNotPresent`                                              |
| `env`                                             | Additional environmental variables                            | `{}`                                                        |
| `credentials.name`                                | Dome9 credential secret                                       | `dome9-creds`                                               |
| `credentials.secret`                              | Dome9 APISecret                                               | `CHANGEME`                                                  |
| `credentials.user`                                | Dome9 APIID                                                   | `CHANGEME`                                                  |
| `clusterID`                                       | Cluster ID in Dome9 database                                  | `CHANGEME`                                                  |
| `resources`                                       | Resources required (e.g. CPU, memory)                         | `{}`                                                        |
| `podAnnotations`                                  | Arbitrary non-identifying metadata                            | `{}`                                                        |
| `nodeSelector`                                    | Node labels for pod assignment                                | `{}`                                                        |
| `tolerations`                                     | List of node taints to tolerate                               | `[]`                                                        |
| `affinity`                                        | Affinity settings                                             | `{}`                                                        |
| `proxy`                                           | Proxy settings (e.g. http://my-proxy.com:443)                 | `{}`                                                        |
