# CANFAR ac staging deployment

This directory contains the CANFAR environment values for the OpenCADC ac
service image `bucket.canfar.net/ac:1.5.0-20260127T224241`. The chart and
configuration examples are maintained with the application source under
`opencadc/ac/ac/helm`, following the same layout as `opencadc/doi/doi/helm`.

Before syncing `canfar-ac-staging`, ensure that:

1. ac chart `0.1.0` is available in the `skaha-system` chart repository.
2. `bucket-registry-auth` exists in `canfar-system-staging`.
3. The LDAP server, proxy user, and directory DN values in `base.yaml` have
   been completed by the service owner.
4. `ac-ldap-config` exists in `canfar-system-staging` and contains the
   `proxyPassword` key.
5. If the ac OIDC endpoints are used, each client Secret and the signing-key
   Secret referenced by `oidc` exist in `canfar-system-staging`.
6. The service owner has reviewed the optional read-user, domain, reserved
   group-name, and OIDC client values in `base.yaml`.

The Argo CD Application intentionally uses manual sync until these prerequisites
are complete.
