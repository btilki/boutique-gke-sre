# Log-based metrics

Custom metrics derived from Cloud Logging for SLIs not exposed natively.

## Purpose

Supplement LB and GKE metrics with application-level signals (e.g. checkout errors, 5xx rates).

## Implemented metrics (topic 13)

| Metric                       | File                     | Use                                   |
| ---------------------------- | ------------------------ | ------------------------------------- |
| `boutique/checkout_attempts` | `checkout-attempts.yaml` | Checkout availability SLO denominator |
| `boutique/checkout_success`  | `checkout-success.yaml`  | Checkout availability SLO numerator   |

## Ready in repo (topic 17)

| Metric                      | File                    | Use                                                      |
| --------------------------- | ----------------------- | -------------------------------------------------------- |
| `boutique/checkout_latency` | `checkout-latency.yaml` | Checkout latency SLO distribution (ms); apply on rebuild |

## Privacy and SLI boundaries

Checkout log filters match `[PlaceOrder]` and `payment went through` messages from `checkoutservice`. Those log lines may contain **user identifiers in message text** (e.g. `user_id`).

| Control                     | Implementation                                                              |
| --------------------------- | --------------------------------------------------------------------------- |
| **No PII in metric labels** | Log-based counters only — no `user_id` or email as metric labels            |
| **Aggregate SLI**           | SLO uses ratio of two counters, not per-user series                         |
| **Log access**              | Restrict Cloud Logging read to platform/SRE roles; retention per org policy |
| **Avoid expanding filters** | Do not add email or user_id to log filters used for metrics                 |

If checkout logs require redaction, update filters in GCP and sync reference YAML here.

## Planned metrics

| Metric                     | Log filter (sketch)                                        | Use                 |
| -------------------------- | ---------------------------------------------------------- | ------------------- |
| `boutique/checkout_errors` | `resource.type="k8s_container" severity>=ERROR "checkout"` | Checkout error SLI  |
| `boutique/frontend_5xx`    | HTTP 5xx from ingress or frontend logs                     | Browse availability |

## Implementation

- Created via Logging API / Console in topic 13 step 4
- Reference YAML in this directory; Terraform option in `terraform/modules/monitoring/`

## Further reading

- [../README.md](../README.md)
- [docs/sre/slos/catalog.md](../../../docs/sre/slos/catalog.md)
- [docs/setup/13-observability-slos.md](../../../docs/setup/13-observability-slos.md) — Security notes
