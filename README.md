# 🚀 ArgoCD GitOps for the Keel Kubernetes Cluster (keel-deploy)

This repository is the **Git source of truth** for Argo CD: `Application` (and optionally `ApplicationSet`) manifests plus **Helm values** used at deploy time. Helm **charts** are built and published from a **separate repository** and served from **Harbor** (OCI or Helm index, as configured in Argo CD).

## Table of contents

- [Domains](#domains)
- [Repository layout](#repository-layout)
- [Configuration placeholders](#configuration-placeholders)
- [Required secrets (values references)](#required-secrets-values-references)
- [Bootstrap install](#bootstrap-install)
- [Adding a new Application](#adding-a-new-application)
- [Charts (Harbor)](#charts-harbor)
- [Git as source of truth](#git-as-source-of-truth)
- [Prerequisites (operators)](#prerequisites-operators)
- [Further detail](#further-detail)

## Domains

Three **independent** product lines—no shared multi-domain deployments:

| Domain         | Application manifests                         | Helm values                          |
| -------------- | --------------------------------------------- | ------------------------------------ |
| canfar.net     | `argocd/applications/canfar.net/<service>/`   | `helm/values/canfar.net/<service>/`  |
| cadc-ccda      | `argocd/applications/cadc-ccda/<service>/`     | `helm/values/cadc-ccda/<service>/`   |
| src.canfar.net | `argocd/applications/src.canfar.net/<service>/` | `helm/values/src.canfar.net/<service>/` |

Each domain has its own web services, namespaces, and Argo bootstrap parent. **Service names are not unique across domains** (for example `skaha` exists under both `canfar.net` and `src.canfar.net`), so this repo keeps a **domain segment** under `applications/` and `helm/values/` to avoid collisions. You can add other top-level trees under `argocd/` or `helm/` later (for example shared charts or config) without reshuffling apps.

## Repository layout

```text
argocd-deploy.git/
├── README.md
├── argocd/
│   ├── applications/
│   │   ├── canfar.net/
│   │   │   ├── <service>/
│   │   │   │   ├── production.yaml
│   │   │   │   ├── staging.yaml
│   │   │   │   └── integration.yaml
│   │   ├── cadc-ccda/
│   │   └── src.canfar.net/
│   └── bootstrap/
│       ├── canfar.net.yaml
│       ├── cadc-ccda.yaml
│       └── src.canfar.net.yaml
└── helm/
    └── values/
        ├── canfar.net/<service>/
        ├── cadc-ccda/example-app/   # template; copy for real services
        └── src.canfar.net/<service>/
```

- **canfar.net:** `skaha`, `science-portal`, `arc`, `storage-ui`, `access`, `web-portal`, `web-root`, `reg`, and others — each service directory has `integration.yaml`, `staging.yaml`, and `production.yaml` where that service is deployed per environment.
- **src.canfar.net:** `skaha`, `science-portal`, `cavern`, `storage-ui`, `posix-mapper` — same pattern; Argo names/namespaces use the `src-` prefix (e.g. `src-skaha-integration`).
- **cadc-ccda** ships a single **`example-app`** template under `argocd/applications/cadc-ccda/example-app/` plus `helm/values/cadc-ccda/example-app/`. Copy and rename for real services; `metadata.name` / namespaces use the **`cadc-example-app-*`** prefix.

> **TODO (maintainers):** The **`cadc-ccda`** domain **will** hold real applications in this repository eventually; which services those are is **not fixed yet**. When the application list is decided and committed under `argocd/applications/cadc-ccda/` and `helm/values/cadc-ccda/`, **remove this note**.

## Configuration placeholders

Before syncing, replace **placeholders** in `argocd/bootstrap/` and `argocd/applications/`:

| Placeholder | Where |
| ----------- | ----- |
| `https://git.example.com/your-org/argo-deploy.git` | This repo’s clone URL (`repoURL` on Git sources) |
| `oci://harbor.example.com/.../charts` and `chart: <name>` / `targetRevision` | Your Harbor OCI project, chart name (often the service name), and version |
| `harbor.example.com/...` in `helm/values/**/base.yaml` | Image registry paths your chart uses |

Child Applications use Argo CD **multiple sources**: Helm chart from Harbor plus a Git source with `ref: values` so `helm.valueFiles` can reference `$values/helm/values/<domain>/<service>/...` in this repository (Argo CD 2.6+).

## Required secrets (values references)

Helm values under `helm/values/` **name** Kubernetes `Secret` objects that must exist in the **destination namespace** for each `Application` (unless you change the values). Create them out-of-band (kubectl, Sealed Secrets, External Secrets, etc.); do not commit secret material to this repo.

The table below lists secret **names** and where they appear. Adjust if your cluster uses different naming.

| Secret name | Typical contents | Referenced from |
| ------------- | ---------------- | ---------------- |
| `bucket-registry-auth` | `dockerconfigjson` (or registry credentials your charts expect) for pulling private images | Staging values: `web-root`, `web-portal`, `access`, `reg` (`imagePullSecrets`) |
| `servops-clientcert` | TLS material for the ServOps client CA/cert bundle (mounted under `/usr/share/tomcat/.ssl/` where charts configure it) | `skaha/base.yaml`, `arc/base.yaml` |
| `cephfs-cephx-admin-key` | CephFS CephX key for the volume driver / storage stanza | `arc/staging.yaml` (`storage.service.spec.cephfs.secretRef`) |
| `arc-uws-db-auth` | UWS ARC database credentials (`username` and `password`) / `integration.canfar.net` | `cavern/integration.yaml`, `cavern/prod.yaml` |

**Notes**

- **Staging namespace:** Several canfar.net staging apps target `canfar-system-staging`; secrets such as `bucket-registry-auth` and volume secrets must exist in that namespace for those releases.
- **Ingress TLS:** Values for `web-portal` and `access` still declare `ingress.tls` in integration and production overlays. If TLS is terminated outside the cluster, you may remove those blocks from values and omit the corresponding TLS secrets at the ingress—keep application-level secrets (RSA keys, client certs, registry pull secrets) as required by each chart.

## Bootstrap install

Bootstrap manifests live under `argocd/bootstrap/`. Use this when you want Argo CD to **manage all child `Application` manifests** under a domain tree from Git (app-of-apps), instead of applying each child by hand.

**Prerequisites**

1. [Prerequisites (operators)](#prerequisites-operators) are satisfied (Argo CD, this repo registered, Harbor if needed).
2. In each file under `argocd/bootstrap/`, set `spec.source.repoURL` (and `targetRevision` if not `main`) to **this** repository—replace placeholders first ([Configuration placeholders](#configuration-placeholders)).

**Install (once per domain you use)**

Each domain has its own bootstrap file (there is **no** single root over all of `argocd/applications/`). Apply the ones you need:

```bash
kubectl apply -f argocd/bootstrap/canfar.net.yaml
kubectl apply -f argocd/bootstrap/cadc-ccda.yaml
kubectl apply -f argocd/bootstrap/src.canfar.net.yaml
```

If you **already** had parents pointing at the old `apps/<domain>` path or children using `$values/values/...`, update the parent `spec.source.path` to `argocd/applications/<domain>` and child `helm.valueFiles` to `$values/helm/values/...`, then commit and let Argo reconcile.

That creates **one parent `Application`** per command. Each parent’s `spec.source.path` is **`argocd/applications/<domain>/`** (for example `argocd/applications/canfar.net`), **not** `argocd/bootstrap/`. After Argo **syncs** that parent, it reads Git and creates or updates **every** child `Application` YAML under that path (recursively). You do **not** `kubectl apply` each child file in day-to-day use.

**Using the Argo CD UI instead of `kubectl`**

Creating the parent via **Create application** is equivalent if you enter the **same** spec: repository = this repo, **path** = `argocd/applications/<domain>` (e.g. `argocd/applications/canfar.net`), destination = this cluster and the namespace where `Application` CRs live (`canfar-argocd` for **canfar.net**; other domains may use `argocd` or a domain-specific namespace). You do **not** set the path to `argocd/bootstrap/` or to a single file inside it.

**After install**

- Trigger or wait for sync on the parent app (or rely on automated sync if enabled).
- Child apps appear in the Argo CD UI; each child then syncs its Helm release (Harbor chart + values from this repo).

## Adding a new Application

Add **Helm values** and **Argo `Application` manifests** to Git. Do **not** put raw Helm values under `argocd/applications/`—only `Application` / `ApplicationSet` YAML.

**1. Values**

Create a directory `helm/values/<domain>/<service>/` with at least:

- `base.yaml` — shared defaults for the chart.
- One overlay per environment you deploy, e.g. `integration.yaml`, `staging.yaml`, `prod.yaml` (names should match what you reference from the `Application`).

Align keys with your chart’s `values.yaml` from Harbor.

**2. Application manifests**

Under `argocd/applications/<domain>/<service>/`, add one YAML file per **environment** that should run at the same time (each env usually has its own Kubernetes namespace). Follow an existing service in that domain or the **`cadc-ccda/example-app`** template.

- **Integration / Staging:** `integration.yaml`, `staging.yaml`.
- **Production:** `production.yaml`.

Each file must be a valid `kind: Application` with:

- Harbor source: `repoURL`, `chart`, `targetRevision` (OCI or registered Helm repo).
- Git values source: `ref: values` and `helm.valueFiles` pointing at `$values/helm/values/<domain>/<service>/...` (see any existing app in that domain).
- `spec.destination` namespace and a unique `metadata.name` (see labels on current apps for naming patterns).

**3. Ship the change**

Commit and push. If the **bootstrap** parent for that domain is already applied and synced, Argo CD will pick up new or updated YAML under `argocd/applications/<domain>/` on the next reconciliation (enable a Git webhook for faster updates).

**4. First-time domain**

If you added a **new** domain folder under `argocd/applications/`, you must also add a matching **`argocd/bootstrap/<domain>.yaml`**, register nothing extra beyond Git, and `kubectl apply` that bootstrap file once so Argo starts managing `argocd/applications/<domain>/`.

## Charts (Harbor)

- Chart packages are **not** stored in this repo.
- Each `Application` references Harbor (`repoURL`, `chart`, `targetRevision` for OCI, or your registered Helm repo) and, when using values from Git, a second source or multiple sources for this repo’s `helm/values/` paths. Adjust fields to match your Argo CD version and Harbor setup.

## Git as source of truth

- Prefer **committed** `Application` YAML under `argocd/applications/` over defining production apps **only** in the Argo CD UI, so changes are reviewable and reproducible.
- **Git push** (plus webhook or polling) drives reconciliation; keep secrets out of plain values (use Sealed Secrets, External Secrets, SOPS, etc.).

## Prerequisites (operators)

1. Argo CD installed on the target cluster(s).
2. This repository **registered** in Argo CD (and credentials if the repo is private).
3. Harbor **registered** in Argo CD as a Helm/OCI source if applications pull charts from it.
4. **AppProject** / RBAC aligned with your domains and namespaces, if you restrict what each team can deploy.

## Further detail

Design decisions and alternatives (ApplicationSet, branch-per-env, etc.) are captured in the project planning notes used when this layout was introduced; extend this README when your team settles conventions (naming, projects, sync policies).
