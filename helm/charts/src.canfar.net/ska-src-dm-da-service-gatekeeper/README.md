# ska-src-dm-da-service-gatekeeper (vendored)

Vendored copy of the SKA SRCNet Gatekeeper Helm chart **0.3.2**, extracted from the canSRC production bundle.

## Why vendored

The published upstream chart does not support running Gatekeeper as a non-root user. This version includes the fix from [upstream MR #42](https://gitlab.com/ska-telescope/src/src-dm/ska-src-dm-da-service-gatekeeper/-/merge_requests/42).

## Removal criteria

When upstream publishes a fixed chart version to a Harbor or GitLab Helm repository:

1. Publish or reference the fixed chart from Harbor.
2. Update `argocd/applications/src.canfar.net/gatekeeper/prod.yaml` to pull from Harbor instead of this Git path.
3. Remove this directory.

## Upstream

- Chart home: https://gitlab.com/ska-telescope/src/src-dm/ska-src-dm-da-service-gatekeeper
- App version: 0.3.2
