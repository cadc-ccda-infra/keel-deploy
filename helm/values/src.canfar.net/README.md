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
| `gatekeeper/` | `ska-src-dm-da-service-gatekeeper` *(vendored)* | SRCNet auth/authz reverse proxy for SODA, prepare-data, echo — **`canfar-cansrc`** |
| `prepare-data/` | `ska-src-dm-local-data-preparer` *(vendored)* | Prepare Data API (dpapi); core, celery-worker, rabbitmq — **`canfar-cansrc`** |
| `soda/` | `ska-src-soda` *(vendored)* | IVOA SODA cutout service; mounts shared `xrootd-pvc` — **`canfar-cansrc`** |

## SKA services — Gatekeeper, prepare-data, and SODA

Gatekeeper, prepare-data (dpapi), and SODA are the **canSRC SKA data-management services**. They deploy **production only** on `src.canfar.net` and are intentionally isolated from the platform stack in `canfar-src-staging`.

### Dedicated namespace: `canfar-cansrc`

All three services run together in namespace **`canfar-cansrc`**, not in `canfar-src-staging` or `canfar-src-workloads`. Argo CD child Applications (`src-gatekeeper-prod`, `src-prepare-data-prod`, `src-soda-prod`) target this namespace with `CreateNamespace=true`. Cluster-internal DNS uses the `*.canfar-cansrc.svc.keel-prod.local` form (for example Gatekeeper backend addresses in `gatekeeper/prod.yaml`).

These services previously lived in legacy namespace `canfar-b-src`; new Git-managed releases replace manual Helm installs there once healthy.

### File layout

SKA service directories use **`base.yaml` + `prod.yaml` only** — there is no `staging.yaml`. Vendored charts and extra manifests live outside `helm/values/`:

```text
helm/values/src.canfar.net/
├── gatekeeper/
│   ├── base.yaml          # Security context, SRCNet IAM/permissions URLs, ingress disabled
│   └── prod.yaml          # Namespace, images, siteCapabilities, Gatekeeper service routes
├── prepare-data/
│   ├── base.yaml          # Security context, pod affinity, skaha ServiceAccount refs
│   └── prod.yaml          # Images, env, PVC claim names (xrootd-pvc, src-cavern-pvc, …)
└── soda/
    ├── base.yaml          # Security context, affinity, skaha ServiceAccount, ingress disabled
    └── prod.yaml          # Image, persistence.existingClaim → xrootd-pvc

helm/charts/src.canfar.net/              # Vendored SKA charts (not OpenCADC chartrepo)
├── ska-src-dm-da-service-gatekeeper/
├── ska-src-dm-local-data-preparer/
└── ska-src-soda/

manifests/src.canfar.net/
├── gatekeeper/prod/                       # Traefik Ingress (chart ingress is disabled)
│   ├── echo-ingress.yaml
│   ├── ping-ingress.yaml
│   ├── prepare-data-ingress.yaml
│   └── soda-ingress.yaml
└── prepare-data/prod/pvc/               # PVCs applied before prepare-data / SODA pods start
    ├── celery-cache-pvc.yaml
    ├── src-cavern-pvc.yaml
    └── xrootd-pvc.yaml

argocd/applications/src.canfar.net/
├── gatekeeper/prod.yaml                   # Helm chart + gatekeeper/prod manifests
├── prepare-data/prod.yaml                 # Helm chart + prepare-data/prod/pvc manifests
└── soda/prod.yaml                         # Helm chart only (no extra Git path)
```

Platform services (science portal, cavern, skaha API, storage UI, posix-mapper) follow the usual three-file pattern under their own directories; see [File layout (platform services)](#file-layout-platform-services) below.

### Values conventions (pre-created cluster resources)

SKA charts expect several resources to **already exist** in `canfar-cansrc`. Values reference them by name; secret material and PV bindings are **not** committed to Git.

| Service | Values key | Expected resource in `canfar-cansrc` | Notes |
| ------- | ---------- | ------------------------------------ | ----- |
| Gatekeeper | `gatekeeper.siteCapabilities.existingSecret: true` | Secret `site-capabilities-client-credentials` | When `existingSecret` is `true`, the chart does **not** render a Secret from `clientId` / `clientSecret`. Create the Secret out-of-band before sync. |
| Gatekeeper echo, prepare-data, SODA | `serviceAccount.create: false`, `name: skaha` | ServiceAccount `skaha` | Shared across SKA workloads; chart does not create it. |
| Gatekeeper echo | `echo.namespace.create: false` | Namespace `canfar-cansrc` | Echo runs in the same namespace as Gatekeeper (`prod.yaml` sets `echo.namespace.name: canfar-cansrc`). |
| Gatekeeper | `gatekeeper.ingress.enabled: false` | Traefik Ingress in `manifests/.../gatekeeper/prod/` | Public paths on `src.canfar.net` terminate at Gatekeeper Service, not per-service Ingress. |
| Prepare Data | `pvc.rse`, `pvc.cavern`, `pvc.celeryCache` in `prod.yaml` | PVCs `xrootd-pvc`, `src-cavern-pvc`, `celery-cache-pvc` | Synced from `manifests/.../prepare-data/prod/pvc/` by `src-prepare-data-prod`. PV label selectors must match before pods schedule. `celery-cache-pvc` is ReadWriteOnce. |
| SODA | `persistence.existingClaim: xrootd-pvc` | PVC `xrootd-pvc` | Chart does not create a claim; mounts `data/dev/deterministic` subpath (see `soda/prod.yaml`). Depends on prepare-data PVC sync. |
| SODA | `ingress.enabled: false` | — | Cutout traffic reaches SODA via Gatekeeper route `/soda`, not a direct Ingress. |

Gatekeeper backend routes in `gatekeeper/prod.yaml` point at in-namespace Services: echo, `ska-src-soda`, and prepare-data `core`.

### Sync order

1. Create **`canfar-cansrc`** prerequisites: Secret `site-capabilities-client-credentials`, ServiceAccount `skaha`.
2. Sync **`src-prepare-data-prod`** so PVCs bind and `core` / `celery-worker` / `rabbitmq` Deployments become ready.
3. Sync **`src-soda-prod`** (needs `xrootd-pvc`).
4. Sync **`src-gatekeeper-prod`** (needs backends and Traefik Ingress manifests).

Cutover steps and smoke tests: [`argocd/applications/src.canfar.net/README.md`](../../../argocd/applications/src.canfar.net/README.md#ska-bundle-production-only).

## File layout (platform services)

Each **platform** service directory follows the repo-wide pattern:

```text
helm/values/src.canfar.net/<service>/
├── base.yaml       # Shared defaults (security context, affinity, SRCNet URLs)
├── staging.yaml    # staging-src.canfar.net overlays
└── prod.yaml       # src.canfar.net overlays (production)
```

Argo CD staging apps merge `base.yaml` then `staging.yaml`. Production platform Applications are added under `argocd/applications/src.canfar.net/` as needed — see [`argocd/applications/src.canfar.net/README.md`](../../../argocd/applications/src.canfar.net/README.md).

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

| Secret | Namespace | Keys / usage |
| ------ | --------- | ------------ |
| `site-capabilities-client-credentials` | `canfar-cansrc` | Site capabilities API client credentials — Gatekeeper (`existingSecret: true`) |
| `science-portal-secrets` | `canfar-src-staging` | `auth-secret` — NextAuth |
| `science-portal-oidc-secret-staging-src` | `canfar-src-staging` | `oidc-client-secret` — science portal and storage UI (staging) |
| `ghcr-at88mph-science-portal` | `canfar-src-staging` | Image pull for science portal chart |
| `cavern-uws-db-auth` | `canfar-src-staging` | Cavern UWS PostgreSQL (staging overlay) |

## Storage and volumes

- **Cavern data:** `cavern/staging.yaml` mounts PVC `canfar-src-cavern-pvc` in `canfar-src-staging`
- **Session home:** `skaha/base.yaml` mounts `canfar-src-workloads-pvc` in `canfar-src-workloads` under `/cavern`

PVC manifests live in `manifests/src.canfar.net/volumes/staging/` and are applied outside the Helm release lifecycle.

## Kueue

`kueue/localQueues/prod.ska.yml` defines `LocalQueue` `ska-default` in `canfar-src-workloads`, bound to cluster queue `ska`. Synced by Argo app `canfar-kueue-staging-src`, not by a Helm chart in this tree.
