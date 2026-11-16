# SLO catalog — boutique-gke-sre

## Purpose

Define SLOs from SLIs, targets, and alert linkages for Online Boutique on `boutique.biroltilki.art`.

## When to use

- Implementing Cloud Monitoring SLOs (Phase 6)
- Incident triage (“are we burning budget?”)
- Game days and error-budget exercises

## Prerequisites

- Workloads running with metrics in Cloud Monitoring or Managed Prometheus
- [architecture/overview.md](../../architecture/overview.md) §13

## Architecture

SLOs are defined in **Cloud Monitoring** from LB, custom, or log-based metrics. Burn-rate alerts route to PagerDuty with runbook URLs. Dashboards in **Grafana** support triage; **Cloud Trace** supports checkout latency debugging.

## Service objectives

Availability SLOs below were on the closed reference path (topic 13). Latency SLOs are optional after rebuild (topic 17) — not claimed as operated.

### Browse (frontend)

| SLI          | Definition                                             | Target      | Window         | Path                   |
| ------------ | ------------------------------------------------------ | ----------- | -------------- | ---------------------- |
| Availability | Successful HTTP responses / total requests to frontend | **99.9%**   | 30-day rolling | Closed path (topic 13) |
| Latency      | p95 request duration (frontend)                        | **< 500ms** | 30-day rolling | Optional (topic 17)    |

**User journey:** Home, product browse, cart view (pre-checkout).

**SLI sources (indicative):**

- Availability: HTTPS LB request count + 5xx ratio, or custom metric from frontend
- Latency: LB backend latency p95 or log-based metric from structured access logs (apply via topic 17)

### Checkout

| SLI          | Definition                                 | Target       | Window         | Path                   |
| ------------ | ------------------------------------------ | ------------ | -------------- | ---------------------- |
| Availability | Successful checkout completions / attempts | **99.95%**   | 30-day rolling | Closed path (topic 13) |
| Latency      | p95 checkout path duration                 | **< 1000ms** | 30-day rolling | Optional (topic 17)    |

**User journey:** Place order via `checkoutservice`.

**SLI sources (indicative):**

- Availability: gRPC/HTTP success rate on `checkoutservice` (OTel or log-based metric)
- Latency: Cloud Trace span p95 for checkout path (frontend → checkout → payment) (apply via topic 17)

## Error budget

| Target            | Monthly error budget (approx.) |
| ----------------- | ------------------------------ |
| 99.9% (browse)    | ~43.2 minutes downtime         |
| 99.95% (checkout) | ~21.6 minutes downtime         |

Policy: [error-budget-policy.md](../error-budget-policy.md)

## Burn-rate alerting

Multi-window burn rates per [burn-rate-alerting.md](burn-rate-alerting.md):

| Window | Multiplier | Response           |
| ------ | ---------- | ------------------ |
| 1h     | 14.4×      | Page               |
| 6h     | 6×         | Page               |
| 1d     | 3×         | Ticket             |
| 3d     | 1×         | Ticket (slow burn) |

## Alert → runbook mapping

| Alert policy                 | Runbook                                                                    | Path                |
| ---------------------------- | -------------------------------------------------------------------------- | ------------------- |
| `browse-availability-burn`   | [browse-availability-burn.md](../runbooks/browse-availability-burn.md)     | Closed path         |
| `checkout-availability-burn` | [checkout-availability-burn.md](../runbooks/checkout-availability-burn.md) | Closed path         |
| `browse-latency-burn`        | [browse-latency-burn.md](../runbooks/browse-latency-burn.md)               | Optional (topic 17) |
| `checkout-latency-burn`      | [checkout-latency-burn.md](../runbooks/checkout-latency-burn.md)           | Optional (topic 17) |
| `uptime-check-failed`        | [uptime-check-failed.md](../runbooks/uptime-check-failed.md)               | Closed path         |
| `bad-deploy-rollback`        | [bad-deploy-rollback.md](../runbooks/bad-deploy-rollback.md)               | Closed path         |
| `redis-cart-down`            | [redis-cart-down.md](../runbooks/redis-cart-down.md)                       | Closed path         |

## Observability ownership

| Signal        | Owner    | Backend                       | Consumer                               |
| ------------- | -------- | ----------------------------- | -------------------------------------- |
| SLOs / SLIs   | SRE      | Cloud Monitoring              | Error budgets, burn alerts → PagerDuty |
| Dashboards    | Platform | Grafana                       | On-call, game days                     |
| Metrics (app) | Platform | Managed Prometheus            | SLO queries, HPA (optional)            |
| Traces        | Platform | Cloud Trace                   | Checkout latency debugging             |
| Logs          | Platform | Cloud Logging                 | Log-based metrics, triage              |
| Errors        | App/SRE  | Error Reporting               | Exception aggregation                  |
| Uptime        | SRE      | Cloud Monitoring uptime check | External probe on storefront URL       |

## Step-by-step implementation

- Availability SLOs + burn alerts: [setup/13-observability-slos.md](../../setup/13-observability-slos.md)
- Latency SLOs + burn alerts + Grafana dashboards: [setup/17-latency-slos-dashboards.md](../../setup/17-latency-slos-dashboards.md) (apply on rebuild)

## Validation

**After rebuild only** (hostnames are offline until then — [dns.md](../../dns.md)):

```bash
gcloud monitoring slos list --project=boutique-gke
curl -I https://boutique.biroltilki.art
```

SLO dashboards show data after traffic; burn alerts tested via [test-alerts.md](../oncall/test-alerts.md).

## Troubleshooting

| Symptom          | Cause                    | Fix                                            |
| ---------------- | ------------------------ | ---------------------------------------------- |
| SLO no data      | Missing metrics          | Verify OTel / LB metrics                       |
| False burn pages | Threshold too aggressive | [burn-rate-alerting.md](burn-rate-alerting.md) |

## Common mistakes

- SLO on lagging indicator only (no user-facing SLI)
- Missing runbook URL on alert policy

## Best practices

- Start with browse + checkout; add service SLOs later if needed
- Review SLO compliance monthly

## Production considerations

- High-cardinality labels inflate cost — avoid per-pod SLO labels

## Security considerations

- SLO data is operational metadata; no PII in log-based SLI filters

## Further reading

- [burn-rate-alerting.md](burn-rate-alerting.md)
- [setup/13-observability-slos.md](../../setup/13-observability-slos.md)
- [Google SRE SLO chapter](https://sre.google/sre-book/service-level-objectives/)
