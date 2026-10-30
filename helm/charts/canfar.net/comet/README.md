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

Validation:

```sh
helm lint . \
  --values ../../../values/canfar.net/comet/base.yaml \
  --values ../../../values/canfar.net/comet/staging.yaml

helm template comet . \
  --namespace comet-staging \
  --values ../../../values/canfar.net/comet/base.yaml \
  --values ../../../values/canfar.net/comet/staging.yaml
```
