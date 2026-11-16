# Argo CD Applications: `dev.canfar.net` (keel-dev)

Child `Application` manifests in this tree deploy **CANFAR development** (`dev.canfar.net`) on the **keel-dev** cluster. They are **not** under `argocd/applications/canfar.net/` so the keel-prod parent `canfar-net-apps` never syncs them.

| Item | Location |
| ---- | -------- |
| Parent (app-of-apps) | `dev-canfar-net-apps` — bootstrap [`argocd/bootstrap/dev.canfar.net.yaml`](../../bootstrap/dev.canfar.net.yaml) |
| Helm values | `helm/values/canfar.net/<service>/dev.yaml` (shared domain with staging/prod) |
| Operator runbook | [`docs/adding-canfar-dev-environment.md`](../../../docs/adding-canfar-dev-environment.md) |

## Applications in Git

| Service | Manifest |
| ------- | -------- |
| reg | [`reg/dev.yaml`](reg/dev.yaml) |
| comet | [`comet/dev.yaml`](comet/dev.yaml) |

Add new services as `<service>/dev.yaml` following **`reg/dev.yaml`** unless the service uses an in-repo chart (see **comet**).

## Labels

All apps here should use:

- `argocd.argoproj.io/domain: dev.canfar.net`
- `argocd.argoproj.io/environment: dev`
- `argocd.argoproj.io/service: <service>`