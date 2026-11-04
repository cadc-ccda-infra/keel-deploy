# COMET Helm chart

This chart deploys the shared CANFAR COMET web service. It intentionally
creates only namespace-scoped resources: one Deployment, one ClusterIP Service,
and an optional Ingress.

COMET currently stores server-side sessions in process memory. The schema fixes
`replicaCount` at `1`, and the Deployment uses the `Recreate` strategy. Introduce
a shared session store before enabling multiple replicas.

The chart never creates application credentials. Set `existingSecret` to a
pre-created Secret in the release namespace. Each key is exposed to COMET as an
environment variable of the same name:

- `FLASK_SECRET_KEY` (required): signs the session cookie and OAuth state.
  Changing it signs out every user.
- `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`: the GitHub OAuth app used to
  connect repositories.
- `GITLAB_CLIENT_ID`, `GITLAB_CLIENT_SECRET`: the GitLab OAuth application used
  to connect repositories.
- `COMET_MMP_CLIENT_SECRET`: shared with MMP (`env.MMP_BASE_URL`) to sign in
  with CADC through the portal. When it is set, MMP holds the CADC client and
  COMET needs no CADC credentials.
- `CADC_OIDC_CLIENT_ID`, `CADC_OIDC_CLIENT_SECRET`: only for direct CADC sign-in
  without MMP. They require a CADC client registered for
  `<COMET_PUBLIC_URL>/oauth/cadc/callback`.

Each OAuth app must list the callback under `env.COMET_PUBLIC_URL`, for example
`https://dev.canfar.net/comet/oauth/github/callback`. Restart the Deployment
after changing the Secret.

`startupProbe`, `readinessProbe`, and `livenessProbe` take complete Kubernetes
probe objects and are rendered as-is. Set one to `null` to omit it.

COMET is mounted under a path on a shared CANFAR host (for example
`https://dev.canfar.net/comet`). Set `env.COMET_PUBLIC_URL` to that URL and
`ingress.path` to its path. COMET then serves the wizard and docs on that one
host, builds https URLs and OAuth callbacks from it, and scopes its cookies to
the host and path. Probes keep using `/healthz` because COMET accepts requests
with or without the prefix. Leave `SESSION_COOKIE_DOMAIN` unset. TLS terminates
in front of the cluster, so `ingress.tls.enabled` stays `false`.

Validation:

```sh
for env in dev staging; do
  helm lint . \
    --values ../../../values/canfar.net/comet/base.yaml \
    --values ../../../values/canfar.net/comet/$env.yaml

  helm template comet . \
    --namespace canfar-comet \
    --values ../../../values/canfar.net/comet/base.yaml \
    --values ../../../values/canfar.net/comet/$env.yaml
done
```
