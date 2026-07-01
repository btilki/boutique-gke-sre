# Cloud Monitoring alert policies

Multi-window burn-rate and supporting alert policies.

## Purpose

PagerDuty-routed alerts with runbook links for SRE response.

## Planned policies

| Policy | Runbook |
|--------|---------|
| `browse-availability-burn` | [docs/sre/runbooks/browse-availability-burn.md](../../docs/sre/runbooks/browse-availability-burn.md) |
| `checkout-latency-burn` | [docs/sre/runbooks/checkout-latency-burn.md](../../docs/sre/runbooks/checkout-latency-burn.md) |
| `uptime-check-failed` | [docs/sre/runbooks/uptime-check-failed.md](../../docs/sre/runbooks/uptime-check-failed.md) |
| `bad-deploy-rollback` | [docs/sre/runbooks/bad-deploy-rollback.md](../../docs/sre/runbooks/bad-deploy-rollback.md) |
| `redis-cart-down` | [docs/sre/runbooks/redis-cart-down.md](../../docs/sre/runbooks/redis-cart-down.md) |

## Notification routing

- PagerDuty integration via Cloud Monitoring notification channel
- Each policy documentation block includes runbook URL

## Further reading

- [../README.md](../README.md)
- [docs/setup/14-pagerduty.md](../../docs/setup/14-pagerduty.md)
