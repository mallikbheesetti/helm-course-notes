# 01 - Course Introduction

Source: `02/course-introduction-slides.pdf`

## Why this course exists

A Kubernetes application is rarely one object. Even a small application
needs a Pod, a Service, and an Ingress. A realistic application adds
ConfigMaps, Secrets, persistent volumes, one or more Deployments, and
multiple Services. Managing those objects by hand with `kubectl` gets
painful quickly:

- **Packaging** - which files belong to which application version?
- **Versioning** - how do you install v1 today and upgrade to v2 safely?
- **Customization** - how do you reuse the same definitions for dev and
  production?
- **Dependencies** - how do you install and version a database chart that
  your application needs?

Helm addresses all four.

## Sample application: Guestbook for Events

The course uses one application throughout, built in two versions.

### Version 1 - frontend only

| Object | Purpose |
| --- | --- |
| Pod | Angular frontend |
| Service | Stable virtual IP and port for the Pod |
| Ingress | HTTP host/path routing to the Service |

### Version 2 - three tiers

| Tier | Objects |
| --- | --- |
| Frontend | ConfigMap, Pod, Service, Ingress |
| Backend API | Secret, Pod, Service |
| Database | Secret, PersistentVolume, PersistentVolumeClaim, Pod, Service |

```
Browser -> Ingress -> frontend Service -> frontend Pod
                                   |
                                   v
                          backend Service -> backend Pod -> MongoDB
```

## Course outline

1. Discovering Helm
2. Installing Kubernetes and Helm
3. Building Helm charts
4. Customizing charts with Helm templates
5. Managing chart dependencies
6. Using existing charts from repositories

The course is theory plus **11 labs**. The labs progressively replace the
raw `kubectl` workflow with Helm.

## Course prerequisites and goals

Prerequisites:

- Basic Kubernetes concepts
- Unix shell
- No programming required, although Go template syntax is easier if you
  have seen a template language before

By the end you should be able to:

- Explain Helm charts, releases, revisions, and repositories
- Build and customize a chart
- Install and manage application versions with Helm
- Reuse and override third-party charts

## Helm 3 scope

The course targets **Helm 3**. Helm 2 differs in architecture (Tiller) and
in several commands. Helm 2 charts are generally compatible with Helm 3,
but Helm 2-specific fields and workflows are not the focus here.

## Source lab repository

The slides point to `https://github.com/phcollignon/helm3`. Lab directory
names in the slides follow this pattern:

- `lab1_kubectl_version1`
- `lab2_kubectl_version2`
- `lab5_helm_chart_version1`
- `lab6_helm_chart_version2`
- `lab7_helm_template_begin` / `lab7_helm_template_final`
- `lab8_helm_template_begin` / `lab8_helm_template_final`
- `lab9_helm_template_begin` / `lab9_helm_template_final`
- `lab10_helm_dependencies_begin` / `lab10_helm_dependencies_final`
- `lab11_helm_repository_begin` / `lab11_helm_repository_final`

The exercises in this repository recreate the same progression without
requiring you to clone the source repository, although you may use it as a
reference.
