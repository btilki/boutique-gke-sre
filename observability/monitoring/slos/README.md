# Cloud Monitoring SLO definitions

Service Level Objective resources for browse and checkout paths.

## Purpose

Define SLIs and targets in Cloud Monitoring aligned with [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md).

## Planned artifacts

| File | SLO |
|------|-----|
| `browse-availability.yaml` | Browse availability 99.9% |
| `browse-latency.yaml` | Browse p95 < 500ms |
| `checkout-availability.yaml` | Checkout availability 99.95% |
| `checkout-latency.yaml` | Checkout p95 < 1000ms |

## Implementation options

- Terraform `google_monitoring_slo` in `terraform/modules/monitoring/`
- YAML exported from Cloud Console for reference

## Validation

```bash
gcloud monitoring slos list --project=boutique-gke
```

## Further reading

- [../README.md](../README.md)
- [docs/sre/error-budget-policy.md](../../docs/sre/error-budget-policy.md)
