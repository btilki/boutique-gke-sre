# Cloud Monitoring alert policies

Multi-window burn-rate and supporting alert policies.

## Purpose

PagerDuty-routed alerts with runbook links for SRE response.

## Runbook registry

Canonical policy → runbook mapping: [`../runbooks.yaml`](../runbooks.yaml)

Validate linkage: `make runbook-lint` or `./scripts/validate-runbook-links.sh`

## Reference policies (applied via Console / scripts)

| Policy                       | Script                                  | Runbook                                                                                   |
| ---------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------- |
| `browse-availability-burn`   | `create-burn-rate-policies.sh`          | [browse-availability-burn.md](../../../docs/sre/runbooks/browse-availability-burn.md)     |
| `checkout-availability-burn` | `create-burn-rate-policies.sh`          | [checkout-availability-burn.md](../../../docs/sre/runbooks/checkout-availability-burn.md) |
| `uptime-check-failed`        | `create-uptime-check.sh`                | [uptime-check-failed.md](../../../docs/sre/runbooks/uptime-check-failed.md)               |
| `bad-deploy-rollback`        | `create-supplemental-alert-policies.sh` | [bad-deploy-rollback.md](../../../docs/sre/runbooks/bad-deploy-rollback.md)               |
| `redis-cart-down`            | `create-supplemental-alert-policies.sh` | [redis-cart-down.md](../../../docs/sre/runbooks/redis-cart-down.md)                       |

## Apply order

```bash
./scripts/create-burn-rate-policies.sh
./scripts/create-uptime-check.sh
./scripts/create-supplemental-alert-policies.sh
./scripts/attach-pagerduty-channel.sh   # topic 14
make runbook-lint
```

## Notification routing

- PagerDuty integration via Cloud Monitoring notification channel `pagerduty-boutique-production`
- Each policy `documentation` block includes runbook URL + [quick-reference](../../../docs/operations/quick-reference.md) link

## Further reading

- [../README.md](../README.md)
- [docs/setup/13-observability-slos.md](../../../docs/setup/13-observability-slos.md)
- [docs/setup/14-pagerduty.md](../../../docs/setup/14-pagerduty.md)
- [docs/operations/quick-reference.md](../../../docs/operations/quick-reference.md)
