# canSRC (`src.canfar.net`) — Argo CD deployment

This tree deploys **canSRC**, the Canadian node of **SRCNet** (the Square Kilometre Array regional compute federation), on the Keel Kubernetes cluster. Public endpoints are served under `staging-src.canfar.net` (staging) and `src.canfar.net` (production). The science portal, storage UI, and Skaha integration use canSRC branding and SRCNet identity and permissions services.

Argo CD manages releases from this repository using an **app-of-apps** parent plus child `Application` manifests. Helm **charts** are pulled from OpenCADC chart repositories; **values** live in `helm/values/src.canfar.net/` in this repo.

## Architecture overview

```text
argocd/bootstrap/src.canfar.net.yaml          (apply once)
        │
        ▼
src-canfar-net-apps  (parent Application)
        │
        ├── src-science-portal-staging
        ├── src-cavern-staging
        ├── src-skaha-staging
        ├── src-storage-ui-staging
        ├── src-posix-mapper-staging
        └── canfar-kueue-staging-src
                │
                ▼
        Helm releases + raw manifests in cluster namespaces
```

| Layer | Namespace | Purpose |
| ----- | --------- | ------- |
| Argo CD `Application` CRs | `canfar-argocd` | Parent and child app definitions |
| Platform services (staging) | `canfar-src-staging` | Cavern, Skaha API, science portal, storage UI, POSIX mapper |
| Interactive sessions & queues | `canfar-src-workloads` | Skaha user sessions, Kueue `LocalQueue`, session PVC |

Skaha **sessions** are scheduled in `canfar-src-workloads` on host `workloads.canfar.net`, while the Skaha **service** and other web-facing components run in `canfar-src-staging` behind `staging-src.canfar.net`.

## Bootstrap

Apply the parent Application once (after [repository placeholders](../../../README.md#configuration-placeholders) are set):

```bash
kubectl apply -f argocd/bootstrap/src.canfar.net.yaml
```

| Field | Value |
| ----- | ----- |
| Parent name | `src-canfar-net-apps` |
| Argo CD project | `canfar` |
| Git path | `argocd/applications/src.canfar.net` |
| `Application` CR namespace | `canfar-argocd` |

The parent uses `directory.recurse: true` so new child YAML under this path is picked up automatically on sync. Automated sync with prune and self-heal is enabled.

## Child applications (staging)

All current child manifests are **staging** overlays. Production Helm values exist under `helm/values/src.canfar.net/` for several services; add matching `production.yaml` (or `prod.yaml`) Application manifests here when production is ready to sync from Git.

| Application | Chart repo | Chart | Version | Destination namespace |
| ----------- | ---------- | ----- | ------- | --------------------- |
| `src-science-portal-staging` | `images.opencadc.org/chartrepo/platform` | `science-portal` | 2.0.0 | `canfar-src-staging` |
| `src-cavern-staging` | platform | `cavern` | 0.10.0 | `canfar-src-staging` |
| `src-skaha-staging` | platform | `skaha` | 1.6.0 | `canfar-src-staging` |
| `src-storage-ui-staging` | `images.opencadc.org/chartrepo/client` | `storageui` | 1.4.4 | `canfar-src-staging` |
| `src-posix-mapper-staging` | platform | `posixmapper` | 0.6.0 | `canfar-src-staging` |
| `canfar-kueue-staging-src` | *(Git path, not Helm)* | — | — | `canfar-src-workloads` |

Helm-based children use **multiple sources** (Argo CD 2.6+): chart from OpenCADC plus a Git source with `ref: values` so value files resolve as `$values/helm/values/src.canfar.net/<service>/...`.

### Kueue

`canfar-kueue-staging-src` syncs only the SKA `LocalQueue` manifest from `helm/values/src.canfar.net/kueue/localQueues/prod.ska.yml`. The cluster-wide Kueue controller and `ClusterQueue` resources are reconciled outside this repo by a ClusterOperator-managed Argo CD application.

## SRCNet integration

canSRC is wired into SRCNet shared services rather than standing alone:

| Concern | Endpoint / identifier |
| ------- | ----------------------- |
| OIDC (SKA IAM) | `https://ska-iam.stfc.ac.uk/` |
| GMS | `ivo://skao.int/gms` |
| Permissions API | `https://permissions.srcnet.skao.int/api` |
| Authn API | `https://authn.srcnet.skao.int/api` |
| Container registries (Cavern / Storage UI) | `spsrc27.iaa.csic.es`, `reg.swesrc.chalmers.se` |
| canfar.net registry (Skaha staging) | `https://staging.canfar.net/reg` |
| Cavern resource ID (staging) | `ivo://canfar.net/staging-src/cavern` |

Skaha staging enables the SRCNet permissions API for session authorization (`canfar-api` v1). Science portal and storage UI authenticate users via SKA IAM OIDC with NextAuth callback paths under `/science-portal`.

## Hostnames and paths (staging)

| Service | Host | Path |
| ------- | ---- | ---- |
| Science portal | `staging-src.canfar.net` | `/science-portal` |
| Cavern (VOS) | `staging-src.canfar.net` | `/cavern` |
| Skaha API | `staging-src.canfar.net` | `/skaha` |
| Storage UI | `staging-src.canfar.net` | `/storage` |
| POSIX mapper | `staging-src.canfar.net` | `/posix-mapper` |

Production values target `src.canfar.net` with the same path layout.

## Prerequisites outside Argo CD

Create these **before** or alongside the first sync. Do not commit secret material to Git.

| Secret | Namespace | Used by |
| ------ | ----------- | ------- |
| `science-portal-secrets` (`auth-secret`) | `canfar-src-staging` | Science portal NextAuth |
| `science-portal-oidc-secret-staging-src` (`oidc-client-secret`) | `canfar-src-staging` | Science portal OIDC, storage UI OIDC |
| `ghcr-at88mph-science-portal` | `canfar-src-staging` | Science portal image pull |
| `cavern-uws-db-auth` | `canfar-src-staging` | Cavern UWS database (staging) |

**Persistent volumes:** CephFS PVCs for cavern and session storage are defined in `manifests/src.canfar.net/volumes/staging/cephfs-pvc.yaml` and must exist (or be applied separately) before Cavern and Skaha sessions can mount storage.

**POSIX mapper database:** JDBC settings are in `helm/values/src.canfar.net/posix-mapper/base.yaml`; ensure connectivity to the mapping database from the cluster.

## Adding production Applications

When production should be managed from Git:

1. Add `production.yaml` (or `prod.yaml`, matching repo convention) under each service directory in this tree.
2. Point `helm.valueFiles` at `base.yaml` plus `prod.yaml` under `helm/values/src.canfar.net/<service>/`.
3. Set `metadata.name` with a `src-` prefix and `staging` replaced by `prod` (for example `src-cavern-prod`).
4. Choose destination namespaces (likely `canfar-src-prod` or equivalent) and align with cluster RBAC and secrets.

Commit and push; the parent `src-canfar-net-apps` Application will create the new child on the next sync.

## Related documentation

- Helm values for this domain: [`helm/values/src.canfar.net/README.md`](../../../helm/values/src.canfar.net/README.md)
- Top-level values layout: [`helm/values/README.md`](../../../helm/values/README.md)
- Repository-wide Argo CD conventions: [root `README.md`](../../../README.md)
