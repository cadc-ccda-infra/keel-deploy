# canSRC (`src.canfar.net`) — Helm values

Helm **values** for deploying **canSRC**, the Canadian SRCNet node, on Keel. Charts are published by OpenCADC and the science-portal project; Argo CD `Application` manifests under `argocd/applications/src.canfar.net/` reference these files via `$values/helm/values/src.canfar.net/...`.

## Services

| Directory | Chart | Role in canSRC |
| --------- | ----- | -------------- |
| `science-portal/` | `science-portal` 2.x | Next.js portal; canSRC branding, links to Cavern, Skaha, storage |
| `cavern/` | `cavern` | VOS/POSIX storage backend for SRCNet data |
| `skaha/` | `skaha` | Interactive notebook/desktop sessions (SRCNet permissions API) |
| `storage-ui/` | `storageui` | Web file browser (`theme: src`, canSRC logo) |
| `posix-mapper/` | `posixmapper` | UID/GID mapping for POSIX-backed VOS |
| `kueue/` | *(raw manifest)* | `LocalQueue` for SKA cluster queue in session namespace |

## File layout

Each service directory follows the repo-wide pattern:

```text
helm/values/src.canfar.net/<service>/
├── base.yaml       # Shared defaults (security context, affinity, SRCNet URLs)
├── staging.yaml    # staging-src.canfar.net overlays
└── prod.yaml       # src.canfar.net overlays (production)
```

Argo CD staging apps merge `base.yaml` then `staging.yaml`. Production values are present for several services; production `Application` manifests are not yet in Git for all of them—see [`argocd/applications/src.canfar.net/README.md`](../../../argocd/applications/src.canfar.net/README.md).

## Environments

| Environment | Public hostname | Cavern resource ID |
| ----------- | --------------- | ------------------ |
| Staging | `staging-src.canfar.net` | `ivo://canfar.net/staging-src/cavern` |
| Production | `src.canfar.net` | `ivo://canfar.net/src/cavern` |

Skaha sessions use host `workloads.canfar.net` and namespace `canfar-src-workloads` in both environments (see `skaha/base.yaml` and env overlays).

## SRCNet-specific configuration

Values tie canSRC to federation services shared across SRCNet nodes:

- **Identity:** `oidcURI: https://ska-iam.stfc.ac.uk/`, `gmsID: ivo://skao.int/gms`
- **Authorization:** Cavern and Skaha reference `permissions.srcnet.skao.int` and `authn.srcnet.skao.int`
- **Registries:** European SRC registries plus canfar.net staging registry for Skaha image cache (staging)
- **Branding:** Science portal `srcnetLogoUrl` and storage UI `logoURL` point at `canSRCLogo.png`

Science portal staging sets `app.useCanfar: false` in `base.yaml` and wires API URLs to the src hostnames rather than main canfar.net services.

## Secrets referenced in values

Create in the target namespace before sync. Names are defined in values, not in this repo’s secret store.

| Secret | Keys / usage |
| ------ | ------------ |
| `science-portal-secrets` | `auth-secret` — NextAuth |
| `science-portal-oidc-secret-staging-src` | `oidc-client-secret` — science portal and storage UI (staging) |
| `ghcr-at88mph-science-portal` | Image pull for science portal chart |
| `cavern-uws-db-auth` | Cavern UWS PostgreSQL (staging overlay) |

## Storage and volumes

- **Cavern data:** `cavern/staging.yaml` mounts PVC `canfar-src-cavern-pvc` in `canfar-src-staging`
- **Session home:** `skaha/base.yaml` mounts `canfar-src-workloads-pvc` in `canfar-src-workloads` under `/cavern`

PVC manifests live in `manifests/src.canfar.net/volumes/staging/` and are applied outside the Helm release lifecycle.

## Kueue

`kueue/localQueues/prod.ska.yml` defines `LocalQueue` `ska-default` in `canfar-src-workloads`, bound to cluster queue `ska`. Synced by Argo app `canfar-kueue-staging-src`, not by a Helm chart in this tree.
