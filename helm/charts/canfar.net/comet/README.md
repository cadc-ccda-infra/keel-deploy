# COMET Helm chart

This chart deploys the shared CANFAR COMET web service. It intentionally
creates only namespace-scoped resources: one Deployment, one ClusterIP Service,
and an optional Ingress.

COMET currently stores server-side sessions in process memory. The schema fixes
`replicaCount` at `1`, and the Deployment uses the `Recreate` strategy. Introduce
a shared session store before enabling multiple replicas.

The chart never creates application credentials. Set `existingSecret` to a
pre-created Secret in the release namespace. Expected keys are environment
variable names such as `FLASK_SECRET_KEY`, `CADC_OIDC_CLIENT_SECRET`,
`GITHUB_CLIENT_SECRET`, and `GITLAB_CLIENT_SECRET`.

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
