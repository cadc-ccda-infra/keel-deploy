# Staging Skaha / Metrics: OTEL, platform stats, Capsule RBAC

Local tracking note (Jira create unavailable). Labels conceptually: `CANFAR`, staging, keel-prod.

## Summary

Enable Metrics OpenTelemetry export on `staging.canfar.net`, keep Skaha platform stats sourced from the Metrics backend, and **do not** flip chart-managed cluster RBAC (`metricsBackend.rbac.enabled` stays `false`).

## 1. OTEL for Metrics backend

**Verified on keel-prod (2026-07-15)** from pod `canfar-skaha-staging-skaha-metrics-api` in `canfar-system-staging`:

| Check | Result |
|-------|--------|
| Prometheus | `3.12.0`, Ready on `:9090` |
| Flag | `web.enable-otlp-receiver=true` |
| Classic OTLP ports `:4317`/`:4318` on `prometheus-operated` / `alloy` | Not usable (connection refused / timeout) |
| Working OTLP HTTP metrics URL | `http://prometheus-operated.monitoring.svc.keel-prod.local:9090/api/v1/otlp/v1/metrics` |
| Chart `telemetry.metrics` | Must stay `false` (chart fails if true); use `metricsBackend.env` `METRICS_OTEL_*` |

Probe: invalid protobuf → HTTP 400 from that path; valid `OTLPMetricExporter` `force_flush` → success.

## 2. Capsule / cluster RBAC (do not change Skaha chart RBAC)

**Evidence:**

- `kubectl create clusterrole ... --dry-run=server` → Forbidden via `system:serviceaccount:capsule-system:capsule-proxy`
- Same for `clusterrolebindings`
- Namespace Role/RoleBinding in `canfar-*` namespaces works (LocalQueue RBAC already present)
- With `metricsBackend.rbac.enabled: false`, SA `canfar-skaha-staging` can still `list`/`get` ClusterQueues `cadc`/`ska` and Metrics platform GET returns Success — grant is ambient / outside this Helm release

**Why this is awkward:** GitOps should own a least-privilege ClusterQueue read binding for the shared Skaha SA. Capsule tenants cannot create cluster-scoped RBAC, but ClusterQueue is cluster-scoped, so Metrics depends on invisible pre-provisioned grants that Argo does not manage with the Skaha app. Preferred end state: platform Tenant/`additionalRoleBindings` (or equivalent) documents the grant; keep chart `metricsBackend.rbac.enabled: false` until that exists.

## 3. Skaha platform stats from Metrics

Already the intended path when `metricsBackend.enabled: true`: chart injects `SKAHA_METRICS_BACKEND_URL` to the in-cluster Metrics Service. Staging image `skaha:1.3.1-rc.1` includes `MetricsDAO` / `PlatformMetricsDAO`. Keep `rbac.clusterRole.create: false` (legacy node listing).

## Delivery

HITL PR updating `helm/values/canfar.net/skaha/staging.yaml` only (no cluster RBAC toggles).
