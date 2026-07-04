# Cloud Monitoring SLO definitions

Service Level Objective resources for browse and checkout paths.

## Purpose

Define SLIs and targets in Cloud Monitoring aligned with [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md).

## Reference artifacts (applied in GCP — topic 13)

| File                         | SLO                          | Status  |
| ---------------------------- | ---------------------------- | ------- |
| `browse-availability.yaml`   | Browse availability 99.9%    | Applied |
| `checkout-availability.yaml` | Checkout availability 99.95% | Applied |
| `browse-latency.yaml`        | Browse p95 < 500ms           | Planned |
| `checkout-latency.yaml`      | Checkout p95 < 1000ms        | Planned |

## Implementation options

- Console / Monitoring API (topic 13)
- Terraform `google_monitoring_slo` in `terraform/modules/monitoring/` (future)

## Validation

Verify in **GCP Console → Monitoring → Services** (`boutique-frontend`, `boutique-checkout`), or:

```bash
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://monitoring.googleapis.com/v3/projects/boutique-gke/services/boutique-frontend/serviceLevelObjectives/browse-availability" \
  | python3 -c "import sys,json; s=json.load(sys.stdin); print(s['displayName'], s['goal'])"
```

> Stable `gcloud` has no `monitoring services list` subcommand. Use Console or the Monitoring REST API.

## Further reading

- [../README.md](../README.md)
- [docs/sre/error-budget-policy.md](../../docs/sre/error-budget-policy.md)
