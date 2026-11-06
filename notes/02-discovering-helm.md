# 02 - Discovering Helm

Source: `03/discovering-helm-slides.pdf`

## The problem with plain `kubectl`

A Kubernetes cluster is a set of API objects. Clients such as `kubectl`,
the Go client, or custom REST clients talk to the Kubernetes API. That is
enough to create objects, but it does not solve:

- Packaging an application into a reusable unit
- Versioning that unit
- Customizing it per environment
- Declaring and resolving dependencies

The course demonstrates the pain directly: deploy Guestbook v1 with
`kubectl`, then upgrade to v2 with `kubectl`. You end up tracking many
files, applying them in the right order, and editing them for every
environment.

## What is Helm

> Helm is a package manager for Kubernetes.

It plays the same role for Kubernetes that `apt`, `yum`, `npm`, `pip`, or
`maven` play for their ecosystems.

| Ecosystem | Package manager | Package unit |
| --- | --- | --- |
| Debian/Ubuntu | `apt` | `.deb` |
| RHEL/CentOS | `yum` | `.rpm` |
| Java | `maven` | Jar, Ear |
| JavaScript | `npm` | Node modules |
| Python | `pip` | Python packages |
| **Kubernetes** | **Helm** | **Charts** |

Command analogy:

```bash
# System packages
apt update
apt install mysql

# Kubernetes packages
helm repo update
helm install mysql stable/mysql
```

## Core concepts

### Chart

A **chart** is the package: a directory (or `.tgz` archive) containing
Kubernetes manifests, default values, metadata, and optional dependencies.
A chart is a definition, not a running instance.

### Release

A **release** is a running instance of a chart in a cluster. Installing
the same chart twice with two release names creates two independent sets
of Kubernetes objects.

### Revision

Every install, upgrade, or rollback creates a new **revision** of a
release. Helm stores the history so you can inspect and roll back to an
earlier revision.

### Repository

A **repository** is an HTTP server that hosts packaged charts plus an
`index.yaml` describing what is available.

## How Helm works

```
Chart + values
      |
      v
    Helm  ---> renders manifests ---> Kubernetes API ---> Cluster
      ^
      |
  release state (history, revisions)
```

Helm renders templates into Kubernetes manifests, submits them to the
cluster, and records the release metadata.

### Install

`helm install <release> <chart>` renders the chart with values, creates
the objects, and records revision 1.

### Upgrade and the three-way merge

An upgrade is not a blind re-apply. Helm compares three states:

1. The **old chart** manifests (what the previous revision rendered)
2. The **live state** in the cluster (possibly changed by other actors)
3. The **new chart** manifests (the desired state)

It produces a patch from those three inputs. This matters when something
else has changed a live object: Helm tries not to silently discard changes
it did not make.

### Namespaces

Helm is namespace-aware. A release lives in a namespace, and by default
its objects are created there. Two releases with the same name can exist
in different namespaces.

```bash
helm install dev guestbook --namespace dev --create-namespace
helm install test guestbook --namespace test --create-namespace
```

## Helm 2 versus Helm 3

Helm 2 used a server-side component called **Tiller**. The Helm client
talked to Tiller over gRPC, and Tiller performed changes in the cluster.

```
Helm 2:  helm client --gRPC--> Tiller (in cluster) --> Kubernetes API
Helm 3:  helm client ------------------------------> Kubernetes API
```

Tiller had broad cluster permissions and was a security concern. Helm 3
removed it: the client talks directly to the Kubernetes API using the
user's credentials. Release state is stored as Secrets in the release
namespace.

## Helm features

| Feature | Meaning |
| --- | --- |
| Charts | Package Kubernetes manifests into a reusable unit |
| Templates | Render manifests dynamically from values |
| Dependencies | Declare charts your chart needs |
| Repositories | Publish and discover packaged charts |

## Key takeaways

- Helm is a package manager, not a replacement for Kubernetes.
- Chart = definition, Release = instance, Revision = version of an instance.
- Helm 3 is client-only; there is no Tiller.
- Upgrades use a three-way merge between old manifest, live state, and new
  manifest.
- Namespaces isolate releases.
