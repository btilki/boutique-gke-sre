# GCP Cloud Monitoring (SRE layer)

SLOs, alert policies, uptime checks, and log-based metrics for boutique-gke-sre.

## Purpose

GCP-native monitoring artifacts that drive PagerDuty and error-budget policy. Complements in-cluster Prometheus/Grafana.

## Layout

| Directory | Contents |
|-----------|----------|
| `slos/` | Cloud Monitoring SLO definitions (browse, checkout) |
| `alert-policies/` | Burn-rate and operational alert policies |
| `uptime-checks/` | HTTPS checks for storefront and Argo CD |
| `log-based-metrics/` | Custom SLI metrics from Cloud Logging |

## Dependencies

- Terraform `monitoring` module or manual Console setup (Phase 6)
- PagerDuty notification channel ([docs/setup/14-pagerduty.md](../../docs/setup/14-pagerduty.md))
- Runbooks in `docs/sre/runbooks/` (linked from each policy)

## Phase

Implemented in Phase 6. Setup guide: [docs/setup/13-observability-slos.md](../../docs/setup/13-observability-slos.md).

## Further reading

- [observability/README.md](../README.md)
- [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md)
