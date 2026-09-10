# CANFAR AC staging deployment

This directory contains the values and handoff templates for the OpenCADC AC
service image `bucket.canfar.net/ac:1.5.0-20260127T224241`.

Before syncing `canfar-ac-staging`, ensure that:

1. AC chart `0.1.0` is available in the `skaha-system` chart repository.
2. `bucket-registry-auth` exists in `canfar-system-staging`.
3. `ac-runtime-config` exists in `canfar-system-staging` and contains a
   completed `ac-ldap-config.properties`.
4. If the AC OIDC endpoints are used, `ac-runtime-config` also contains
   `ac-oidc-clients.properties`, `oidc-rsa256-pub.key`, and
   `oidc-rsa256-priv.key`.
5. The service owner has reviewed the optional read-user, domain, and reserved
   group-name values currently left empty in `base.yaml`.

The Argo CD Application intentionally uses manual sync until these prerequisites
are complete.
