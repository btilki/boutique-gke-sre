# Cloud Monitoring SLO definitions

Service Level Objective resources for browse and checkout paths.

## Purpose

Define SLIs and targets in Cloud Monitoring aligned with [docs/sre/slos/catalog.md](../../../docs/sre/slos/catalog.md).

## Reference artifacts

| File                         | SLO                                       | Status                                           |
| ---------------------------- | ----------------------------------------- | ------------------------------------------------ |
| `browse-availability.yaml`   | Browse availability 99.9%                 | Applied (topic 13; cluster later decommissioned) |
| `checkout-availability.yaml` | Checkout availability 99.95%              | Applied (topic 13; cluster later decommissioned) |
| `browse-latency.yaml`        | Browse p95 &lt; 500ms (goal 0.95 ≤ 500ms) | **Ready in repo** — apply via topic 17           |
| `checkout-latency.yaml`      | Checkout p95 &lt; 1000ms (goal 0.95 ≤ 1s) | **Ready in repo** — apply via topic 17           |

### Latency SLI notes

| SLO                | Metric source                                                                 | Prerequisite                                                                                                              |
| ------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `browse-latency`   | HTTPS LB `https/total_latencies` (same `url_map_name` as browse availability) | Ingress + traffic                                                                                                         |
| `checkout-latency` | Log-based DISTRIBUTION `boutique/checkout_latency`                            | [../log-based-metrics/checkout-latency.yaml](../log-based-metrics/checkout-latency.yaml); fallback Trace/OTel in topic 17 |

Burn alerts for latency SLOs: `browse-latency-burn`, `checkout-latency-burn` (topic 17 — reference YAML + `scripts/create-latency-burn-rate-policies.sh`).

## Implementation options

- Console / Monitoring API — availability: topic 13; latency: topic 17
- Terraform `google_monitoring_slo` in `terraform/modules/monitoring/`

## Validation

Verify in **GCP Console → Monitoring → Services** (`boutique-frontend`, `boutique-checkout`), or:

```bash
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://monitoring.googleapis.com/v3/projects/boutique-gke/services/boutique-frontend/serviceLevelObjectives/browse-latency" \
  | python3 -c "import sys,json; s=json.load(sys.stdin); print(s['displayName'], s['goal'])"
```

> Stable `gcloud` has no `monitoring services list` subcommand. Use Console or the Monitoring REST API.
> Repo-only check today: files exist and match [catalog.md](../../../docs/sre/slos/catalog.md) targets.

## Further reading

- [../README.md](../README.md)
- [docs/sre/error-budget-policy.md](../../../docs/sre/error-budget-policy.md)
- [docs/setup/17-latency-slos-dashboards.md](../../../docs/setup/17-latency-slos-dashboards.md) — topic 17
