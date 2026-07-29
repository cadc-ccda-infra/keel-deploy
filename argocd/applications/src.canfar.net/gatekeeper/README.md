# Gatekeeper

Disabled service for now.  Recreate from YAML below when ready.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: src-gatekeeper-prod
  namespace: canfar-argocd
  labels:
    argocd.argoproj.io/domain: src.canfar.net
    argocd.argoproj.io/environment: production
    argocd.argoproj.io/service: gatekeeper
spec:
  project: canfar
  sources:
    - repoURL: https://github.com/cadc-ccda-infra/keel-deploy.git
      targetRevision: main
      path: helm/charts/src.canfar.net/ska-src-dm-da-service-gatekeeper
      helm:
        valueFiles:
          - $values/helm/values/src.canfar.net/gatekeeper/base.yaml
          - $values/helm/values/src.canfar.net/gatekeeper/prod.yaml
    - repoURL: https://github.com/cadc-ccda-infra/keel-deploy.git
      targetRevision: main
      ref: values
    - repoURL: https://github.com/cadc-ccda-infra/keel-deploy.git
      targetRevision: main
      path: manifests/src.canfar.net/gatekeeper/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: canfar-cansrc
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
```
