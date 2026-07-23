# Cloud Monitoring alert policies

Multi-window burn-rate and supporting alert policies.

## Purpose

PagerDuty-routed alerts with runbook links for SRE response.

## Runbook registry

Canonical policy → runbook mapping: [`../runbooks.yaml`](../runbooks.yaml)

Validate linkage: `make runbook-lint` or `./scripts/validate-runbook-links.sh`

## Reference policies (applied via Console / scripts)

| Policy                       | Script                                                     | Runbook                                                                                   |
| ---------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `browse-availability-burn`   | `create-burn-rate-policies.sh`                             | [browse-availability-burn.md](../../../docs/sre/runbooks/browse-availability-burn.md)     |
| `checkout-availability-burn` | `create-burn-rate-policies.sh`                             | [checkout-availability-burn.md](../../../docs/sre/runbooks/checkout-availability-burn.md) |
| `browse-latency-burn`        | `create-latency-burn-rate-policies.sh`                     | [browse-latency-burn.md](../../../docs/sre/runbooks/browse-latency-burn.md)               |
| `checkout-latency-burn`      | `create-latency-burn-rate-policies.sh`                     | [checkout-latency-burn.md](../../../docs/sre/runbooks/checkout-latency-burn.md)           |
| `uptime-check-failed`        | `create-uptime-check.sh` + `create-argocd-uptime-check.sh` | [uptime-check-failed.md](../../../docs/sre/runbooks/uptime-check-failed.md)               |
| `bad-deploy-rollback`        | `create-supplemental-alert-policies.sh`                    | [bad-deploy-rollback.md](../../../docs/sre/runbooks/bad-deploy-rollback.md)               |
| `redis-cart-down`            | `create-supplemental-alert-policies.sh`                    | [redis-cart-down.md](../../../docs/sre/runbooks/redis-cart-down.md)                       |

Latency burn policies require latency SLOs from topic 17. Runbooks: [browse-latency-burn.md](../../../docs/sre/runbooks/browse-latency-burn.md), [checkout-latency-burn.md](../../../docs/sre/runbooks/checkout-latency-burn.md).

## Apply order

```bash
./scripts/create-burn-rate-policies.sh              # topic 13 — availability
./scripts/create-latency-burn-rate-policies.sh      # topic 17 — latency (after latency SLOs exist)
./scripts/create-uptime-check.sh                    # topic 13 — storefront + policy
./scripts/create-argocd-uptime-check.sh             # topic 18 — Argo CD check; add OR condition
./scripts/create-supplemental-alert-policies.sh
./scripts/attach-pagerduty-channel.sh               # topic 14
make runbook-lint
```

## Notification routing

- PagerDuty integration via Cloud Monitoring notification channel `pagerduty-boutique-production`
- Each policy `documentation` block includes runbook URL + [quick-reference](../../../docs/operations/quick-reference.md) link

## Further reading

- [../README.md](../README.md)
- [docs/setup/13-observability-slos.md](../../../docs/setup/13-observability-slos.md)
- [docs/setup/17-latency-slos-dashboards.md](../../../docs/setup/17-latency-slos-dashboards.md) — topic 17
- [docs/setup/14-pagerduty.md](../../../docs/setup/14-pagerduty.md)
- [docs/operations/quick-reference.md](../../../docs/operations/quick-reference.md)
