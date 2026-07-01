# Log-based metrics

Custom metrics derived from Cloud Logging for SLIs not exposed natively.

## Purpose

Supplement LB and GKE metrics with application-level signals (e.g. checkout errors, 5xx rates).

## Planned metrics

| Metric | Log filter (sketch) | Use |
|--------|---------------------|-----|
| `boutique/checkout_errors` | `resource.type="k8s_container" severity>=ERROR "checkout"` | Checkout SLI |
| `boutique/frontend_5xx` | HTTP 5xx from ingress or frontend logs | Browse availability |

## Implementation

- `google_logging_metric` in Terraform `monitoring` module, or
- Console-created metrics exported as reference YAML

## Further reading

- [../README.md](../README.md)
- [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md)
