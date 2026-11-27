```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: src-prepare-data-staging
  namespace: canfar-argocd
  labels:
    argocd.argoproj.io/domain: src.canfar.net
    argocd.argoproj.io/environment: staging
    argocd.argoproj.io/service: prepare-data
spec:
  project: canfar
  sources:
    - repoURL: https://artefact.skao.int/repository/helm-internal/
      chart: ska-src-dm-local-data-preparer
      targetRevision: 0.3.10
      helm:
        releaseName: dpapi
        valueFiles:
          - $values/helm/values/src.canfar.net/prepare-data/base.yaml
          - $values/helm/values/src.canfar.net/prepare-data/staging.yaml
    - repoURL: https://github.com/cadc-ccda-infra/keel-deploy.git
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: canfar-src-staging
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
