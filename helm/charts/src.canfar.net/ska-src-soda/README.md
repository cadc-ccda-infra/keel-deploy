# ska-src-soda (vendored)

Vendored copy of the SKA SODA Helm chart **0.0.5**, extracted from the canSRC production bundle.

## Why vendored

The published upstream chart does not support running SODA as a non-root user. This version includes the fix from [upstream MR #22](https://gitlab.com/ska-telescope/src/src-ia/ska-src-ia-vo-soda-deployment/-/merge_requests/22).

## Upstream

- Chart home: https://gitlab.com/ska-telescope/src/src-ia/ska-src-ia-vo-soda-deployment
- Chart version: 0.0.5
- App version: 1.6.2

## Removal criteria

When upstream publishes a fixed chart version to a shared Helm repository:

1. Update `argocd/applications/src.canfar.net/soda/prod.yaml` to pull from that repository instead of this Git path.
2. Remove this directory.
