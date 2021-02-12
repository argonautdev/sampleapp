# Documentation

## Introduction

This repository contains user documentation for setup of the infrastructure and deployments using Argonaut.

There are the following sections:

1. Concepts
2. Architecture
3. Setting up infrastructure
4. Deploying services

## Concepts

### Terminology

| Term         | Translation                                                                                                                                                                                                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cluster      | Kubernetes cluster, setup and managed by Argonaut.                                                                                                                                                                                                                              |
| Cluster name | The name given to a kubernetes cluster. This is referenced by applications for their deployment                                                                                                                                                                                 |
| Node         | A compute instance on which the kubernetes control plane and the applications run. For AWS, it is an EC2 instance.                                                                                                                                                              |
| Environment  | The environments targeted by a particular deployment or supported by a cluster or node. In an Argonaut setup, the environment is a namespace within a cluster. Each cluster can have one or more environments                                                                   |
| Namespace    | A namespace is a kubernetes construct for logical separation of resources within a cluster. For end user purposes, a namespace is an environment. Note: As a part of the Argonaut setup, there are two reserved namespaces that are created and used `tools` and `istio-system` |
| art          | Argonaut Resource Templates. Refers to the CLI tool used to perform actions like deploying infrastructure and services                                                                                                                                                          |
| Helm         | A package manager for kubernetes                                                                                                                                                                                                                                                |
| kubectl      | CLI for managing and monitoring kubernetes resources                                                                                                                                                                                                                            |
| Istio        | Service mesh used for managing ingress, traffic routing, reverse proxy, secure inter-service communication within the cluster and more                                                                                                                                          |
| Grafana      | Tool used for monitoring the state of the cluster. This also serves as the front for viewing logs (via Loki), traces (via Jaeger), and accessing Prometheus metrics. Alarms can also be set from here.                                                                          |
| Loki         | Tool used for viewing logs and is responsible for pushing them to `s3` for long term storage and retrieval                                                                                                                                                                      |
| Jaeger       | Distributed tracing tool built by Uber                                                                                                                                                                                                                                          |
| Letsencrypt  | SSL certificate provider                                                                                                                                                                                                                                                        |
| cert-manager | Service that does automatic validation of owned domains and provisions letsencrypt certifcates                                                                                                                                                                                  |
| Fluent-bit   | Log aggregator and router to gather logs from various places and push it to multiple destinations. Used for pushing logs from pods, containers, and nodes to Loki, which in turn pushes it to `s3`                                                                              |
| Kiali        | A "frontend" for istio to monitor the network state and manage the configuration of various applications and services                                                                                                                                                           |
| Prometheus   | Collects metrics from various applications and infrastructure endpoints and makes it easy to monitor, aggregate, and query                                                                                                                                                      |

---

Cloudwatch ++

## Architecture

EC2 | Kubernetes | Environments | Applications | Pods | Services | Ingress | End User

art.yaml
art-cluster.yaml
serviceType
cloudCluster
cloudRegion
cloudProvider
artDirGitURL
gitBranch
imageRegistry
| Stateful service |
| Rollout strategies |
| Stateless service |

---

1. Install `art` after downloading it from the release page
2. Install depenedencies `aws`, `eksctl`, `kubectl`, `helm` using `art init dependencies`

3.

nodeGroups.name can't have "\_" in them

Need to manually setup ingress and loadbalancer ports
Need to manually setup loki credentials
Need to provide deployment logs inline with the deployment

## Quick start

There are two functions that the tool enables:

1. Managing infrastructure
2. Managing deployments

### Infrastructure

The configuration for the infrastructure to be setup is provided through an `art-cluster` file in yaml.

Steps:

1. Get the `art` cli tool for linux [here](https://github.com/argonautdev/app-actions/releases/download/v0.1.0/art)
2. Run the following to download the dependencies (`aws cli`, `kubectl`, `helm`, `eksctl`). This needs to be run just once. Sources you can install these tools from are listed in a separate section.
3. Create an `art-cluster.yaml` file. A fully annotated sample is given below.
4. Run `aws configure` and plug in your credentials
5. Run `art cluster create -f art-config.yaml -k $AWS_ACCESS_KEY_ID -v $AWS_SECRET_ACCESS_KEY`. This process takes ~20-25 minutes for AWS to setup the cluster.
6. Copy over the loadbalancer address that is output at the end of this onto _all_ the domains that are provided in the `art-cluster.yaml` file in `domainName` and `otherDomains`.

> The `art cluster create` command can be run with an optional `-d` or `--dryrun` to just generate the configuration files without applying them and exit.

Options for the `art cluster` command are

```
Create a k8s cluster with specified configurations of compute,
        autoscale, region, and other configurations.

Usage:
  art cluster [flags]
  art cluster [command]

Available Commands:
  create      Create a cluster with argonaut
  delete      Delete an argonaut cluster
```

> Note: A file that is used to configure the cluster is called an `art-cluster` file. This is a generic way of referring to the clsuter configuration file. It does not mean that the file has to be named `art-cluster.yaml`.

An example `art-cluster.yaml` file is given below

```yaml
argonaut:
domainName: "tritonhq.io"
otherDomains: ["dev.tritonhq.io", "tools.tritonhq.io"]
orgOwnerEmail: "surya@argonaut.dev" # Used for letencrypt provisioning
name: "dev"
region: "us-east-2" # Mumbai
logBucketName: "tritohq-app-logs" # s3 bucket name that needs to be provisioned separately before cluster creation
nodeGroups:
- name: dev # Name should contain only [a-zA-Z0-9]
 type: spot # Use AWS spot instances for cost savings
 instanceType: "t3a.medium"
 minNodes: 0
 maxNodes: 5
 desiredNodes: 3
 volumeSize: 10 # storage associated with each node (EC2 instance) in gigabytes
 environments: ["dev"] # List of environments to be supported by this compute group
- name: prod
 type: "ondemand"
 instanceType: "m5.2xlarge"
 minSize: 0
 maxSize: 5
 desiredCapacity: 4
 volumeSize: 20
 env: ["prod"]
```

| Field                        | Description                                                                                                                                                                                  |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `argonaut`                   | Section contains the metadata to instruct argonaut configure various services                                                                                                                |
| `argonaut.domainName`        | The root domain that would be setup for ingress                                                                                                                                              |
| `argonaut.orgOwnerEmail`     | Email address to send `letsencrypt` notifications to, if any                                                                                                                                 |
| `argonaut.name`              | Name of the cluster. Needs to be starting with an alphabet and [a-zA-Z0-9-]                                                                                                                  |
| `argonaut.region`            | The [aws region](https://docs.aws.amazon.com/awsec2/latest/userguide/using-regions-availability-zones.html#concepts-available-regions) in which the cluster is to be setup                   |
| `argonaut.logBucketName`     | The s3 bucket, in the same region as the cluster, that logs should be written to                                                                                                             |
| `nodeGroups`                 | Each nodeGroup is a group of the same kind of EC2 instance eg. `t3.large`. Each nodeGroup can scale based on demand automatically and supports a specified set of environments               |
| `nodeGroups.name`            | Name of node group. Needs to be starting with an alphabet and [a-zA-Z0-9-]                                                                                                                   |
| `nodeGroups.type`            | Can be one of `ondemand` or `spot`. Spot instances can have significant savings for non-production environments. Ondemand is recommended for production environments                         |
| `nodeGroups.instanceType`    | AWS [instance type](https://aws.amazon.com/ec2/instance-types/)                                                                                                                              |
| `nodeGroups.minSize`         | Minimum number of nodes in this group. Can be `0`                                                                                                                                            |
| `nodeGroups.maxSize`         | Minimum number of nodes in this group.                                                                                                                                                       |
| `nodeGroups.desiredCapacity` | The number of nodes to start the cluster with. This needs to be a number between `nodeGroups.minSize` and `nodeGroups.maxSize`                                                               |
| `nodeGroups.volumeSize`      | Capacity of the disk to be attached to each node in GB. This is used for the root filesystems and any ephemeral storage for the containers that are running. This is not persistent storage. |
| `nodeGroups.env[]`           | List of environments that this compute node group supports. While each environment can be supported by multiple nodeGroups, it is recommended to have an environment per nodeGroup.          |

### Application service deployments

Deployments are made extremely simple through the `art` cli that can be invoked directly or through the CI workflows for any containerized service.
The steps to get started are:

1. Run `art app deploy -f art.yaml -k $AWS_ACCESS_KEY_ID -v $AWS_SECRET_ACCESS_KEY -p $CONTAINER_REGISTRY_ACCESS_TOKEN`. Other values from the `art.yaml` file can be overridden through the command line.
2. There is no step 2.

Other options for running the command are below. Noteworthy is the `-d` aka `--dryrun` command which generates the configs for deployment and exits.

```
Usage:
  art app deploy [flags]

Flags:
  -k, --access-key-id string          AWS_ACCESS_KEY_ID for aws
  -v, --access-key-token string       AWS_SECRET_ACCESS_KEY for aws
  -f, --art-file string               art file within the config directory
  -d, --dryrun                        Generate configs and exit
  -e, --env string                    Environment name to deploy to
  -b, --git-branch string             Git branch to monitor for changes
  -g, --git-token string              Git access token for private repos
  -h, --help                          help for deploy
  -i, --image-name string             Image name to deploy
  -r, --image-registry string         Image registry name
  -p, --image-registry-token string   Image registry token to pull private image
  -t, --image-tag string              Image tag to deploy
  -s, --service-type string           one of {external, stateful, stateless}
```

> Note: A file that is used to configure the app deployment is called an `art.yaml` file. This is a generic way of referring to the clsuter configuration file. It does not mean that the file has to be named `art.yaml`.

An example `art.yaml` file is given below

```yaml
---
version: "v1"
appName: "nginx-deployment"
env: "dev"
host: "app.tritonhq.io"

argonaut:
  cloudProvider: aws
  cloudRegion: us-east-2
  cloudCluster: argonaut
  imageRegistry: ghcr.io # corresponding to the image that is to be deployed
  serviceType: "stateless" # One of {stateful, stateless, external}

image: "nginx"
imageTag: "latest"

replicas: 2
minReplicas: 1
maxReplicas: 5

resources:
  requests:
    cpu: "100m"
    memory: "200M"
  limits:
    cpu: "200m"
    memory: "256M"

# entrypoint: ["echo"] # overrides
# cmd: ["Hello World"] # overrides

services:
  - name: "80" # appname will be prefixed, needs to be unique
    protocol: http # http, tls, tcp
    port: 80 # number only
    ingress:
      enabled: true
      tls: "" # "terminated" or "" (not applicable) or "passthrough"
      port: 80
      path: "/nginx" # prefix regex match
#   - name: "443" # appname will be prefixed, needs to be unique
#     protocol: tls # http, tls, tcp
#     port: 443 # number only
#     ingress:
#       enabled: true
#       tls: "terminated" # "terminated" or "" (not applicable) or "passthrough"
#       port: 80
#       path: "/" # prefix regex match

# Can only do one of the httpGet and exec handler methods for livenessProbe
livenessProbe:
  httpGet:
    path: /
    port: http
  # exec:
  #   command:
  #     - sh
  #     - -c
  #     - |
  #       #!/usr/bin/env sh
  #       test -f /etc/
  failureThreshold: 5
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5

# Can only do one of the httpGet and exec handler methods for readinessProbe
readinessProbe:
  # Handler 1
  httpGet:
    path: /
    port: 80
  # # Handler 2
  # exec:
  #   command:
  #     - sh
  #     - -c
  #     - |
  #       #!/usr/bin/env sh
  #       test -f /etc/
  # Common fields
  failureThreshold: 5
  initialDelaySeconds: 10
  successThreshold: 3
  periodSeconds: 10
  timeoutSeconds: 5
```

#### Dependency installation

```bash
#!/bin/bash

 # SETUP kubectl

 echo "Setting up kubectl"
 curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
 chmod +x ./kubectl
 mv kubectl ./bin

 # SETUP aws configure

 echo "Setting up aws-cli"

 curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
 sudo installer -pkg AWSCLIV2.pkg -target /

 # SETUP istioctl 1.8.1

 curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.8.1 TARGET_ARCH=x86_64 sh -
 mv istio-1.8.1/bin/istioctl ./bin
 chmod a+x istio-1.8.1/bin/istioctl
 rm -rf istio-1.8.1/

 # SETUP helm

 curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

 # SETUP kustomize

 curl -s "https://raw.githubusercontent.com/\
 kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
 chmod a+x kustomize
 mv kustomize ./bin

 ####################

 # Install art (compiled for linux/amd64)

 echo "installing art"
 curl -sL "https://github.com/argonautdev/app-actions/releases/download/v0.1.0/art" -o art
 chmod a+x art
 mv art ./bin
 ####################
```
