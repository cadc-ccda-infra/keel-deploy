# ac 1.5.0 configuration templates

These templates target `bucket.canfar.net/ac:1.5.0-20260127T224241` and are
based on the `opencadc/ac` README, examples, and configuration parser at the
source revision corresponding to that image build.

Copy the required `.example` files to a secure location, remove the `.example`
suffix, and replace every `<FILL_...>` placeholder. Do not put completed files,
passwords, client secrets, or private keys in this repository. This directory's
`.gitignore` intentionally ignores completed files.

## Ownership

| File | Filled by | Sensitive |
| --- | --- | --- |
| `ac.properties` | ac service owner | No |
| `ac-ldap-config.properties` | LDAP/ac administrator | Yes (`proxyPassword`) |
| `ac-group-names.properties` | ac service owner | No |
| `ac-domains.properties` | ac/OIDC service owner | No |
| `ac-oidc-clients.properties` | ac/OIDC service owner | Yes (client secrets) |
| `catalina.properties` | Platform/ingress owner | No |
| `cadc-registry.properties` | Platform/registry owner | No |
| `cadc-log.properties` | Platform/ac service owner | Treat `secret` as sensitive if configured |
| `oidc-rsa256-pub.key` | ac/OIDC service owner | No |
| `oidc-rsa256-priv.key` | ac/OIDC service owner | Yes |

The signing key files have no text template. Obtain the existing matching key
pair for a migration. Generate a new pair only for an isolated environment
whose clients will be configured to trust the new public key.

## LDAP credential format

This deployment uses `proxyUser` and `proxyPassword` directly in
`ac-ldap-config.properties`, as required by the ac 1.5.0 ldap service and
confirmed by the service owner. Do not add `dbrcHost` or a `.dbrc` file.

The completed sensitive files should be installed as Kubernetes Secrets in the
destination namespace and projected into the container's `/config` directory.
