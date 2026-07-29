# ska-src-dm-local-data-preparer (vendored)

Vendored copy of the SKA Prepare Data (dpapi) Helm chart **0.2.1**, extracted from the canSRC production bundle.

## Why vendored

The active production deployment uses this bundled chart version with custom images on `images.opencadc.org`. Vendoring keeps the release aligned with the manual deploy until a fixed chart is published to a shared Helm repository.

## Upstream

- GitLab project: https://gitlab.com/ska-telescope/src/src-dm/ska-src-dm-local-data-preparer (project 62139180)
- Chart version: 0.2.1
- App version: 0.2.1

## Removal criteria

When a suitable chart version is published to Harbor or the GitLab Helm package registry:

1. Update `argocd/applications/src.canfar.net/prepare-data/prod.yaml` to pull from that repository instead of this Git path.
2. Remove this directory.
