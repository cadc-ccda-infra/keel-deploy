# Helm values

This directory holds **Helm value overlays** for Argo CD deployments on the Keel cluster. Charts themselves are **not** stored here—they are pulled from OpenCADC chart repositories (`images.opencadc.org`) or other registered Helm/OCI sources at sync time.

Argo CD child `Application` manifests reference these files using a Git source with `ref: values` and paths such as:

```text
$values/helm/values/<domain>/<service>/base.yaml
$values/helm/values/<domain>/<service>/staging.yaml
```

## Layout

```text
helm/values/
├── README.md                 (this file)
├── canfar.net/<service>/     Main CANFAR platform (canfar.net)
├── cadc-west.canfar.net/     CADC West domain (example-app template)
└── src.canfar.net/<service>/ canSRC — Canadian SRCNet node
```

Each `<service>/` directory typically contains:

| File | Purpose |
| ---- | ------- |
| `base.yaml` | Defaults shared across environments (images, security context, cluster domain, shared API URLs) |
| `integration.yaml` | Integration environment overlay (where used) |
| `staging.yaml` | Staging overlay |
| `prod.yaml` or `production.yaml` | Production overlay |

File names must match what the corresponding `Application` lists in `helm.valueFiles`. Not every service deploys to every environment.

## Domains

| Domain path | Product | Notes |
| ----------- | ------- | ----- |
| `canfar.net/` | CANFAR science platform | skaha, science-portal, arc, storage-ui, access, web-portal, reg, kueue, and others |
| `src.canfar.net/` | **canSRC** (SRCNet) | Canadian node of **SRCNet**; hosts `staging-src.canfar.net` / `src.canfar.net`. See [src.canfar.net/README.md](src.canfar.net/README.md) |
| `cadc-west.canfar.net/` | CADC West | `example-app` template; copy for new services |

**Service names repeat across domains** (for example `skaha` exists under both `canfar.net` and `src.canfar.net`). The domain segment in the path is required so values and Argo apps do not collide.

## canSRC and SRCNet

The `src.canfar.net` tree configures **canSRC**: Canada's participation in **SRCNet**, the regional compute federation for the Square Kilometre Array. That deployment shares SRCNet identity (SKA IAM), permissions APIs, and cross-node container registries while exposing a canSRC-branded science portal, VOS storage (Cavern), interactive sessions (Skaha), and storage management UI on SRC-specific hostnames.

- Values detail: [src.canfar.net/README.md](src.canfar.net/README.md)
- Argo CD apps: [argocd/applications/src.canfar.net/README.md](../../argocd/applications/src.canfar.net/README.md)

canSRC is **independent** from main `canfar.net` values—different hostnames, namespaces (`canfar-src-staging`, `canfar-src-workloads`), and SRCNet service endpoints—even though some integrations (for example Skaha registry cache on `staging.canfar.net/reg`) point at shared CANFAR infrastructure.

## Conventions

1. **Align keys with the chart** — Each `base.yaml` should mirror the chart's `values.yaml` schema from the published chart version pinned in the `Application` (`targetRevision`).
2. **Keep secrets out of Git** — Use `existingSecret` / `secretKey` references; create secrets with kubectl, Sealed Secrets, or External Secrets in the destination namespace.
3. **Hostname and resource IDs in overlays** — Shared tuning stays in `base.yaml`; environment-specific hostnames, OIDC redirect URIs, and `ivo://` resource IDs go in `staging.yaml` / `prod.yaml`.
4. **Raw Kubernetes YAML** — Some paths (for example `kueue/localQueues/`) hold manifests synced directly by Argo CD rather than through Helm. Keep them under the same domain folder for clarity.

## Related paths

| Path | Contents |
| ---- | -------- |
| `argocd/applications/<domain>/` | `Application` CRs that consume these values |
| `argocd/bootstrap/` | App-of-apps parents per domain |
| `manifests/<domain>/` | PVCs and other resources not owned by a Helm release |
| `helm/harbor/` | Harbor chart repo registration helpers |

Repository-wide bootstrap, secrets tables, and adding new applications: [root README.md](../../README.md).
