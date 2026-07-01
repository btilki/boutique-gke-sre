# Game days

Scheduled failure exercises for boutique-gke-sre SRE practice.

## Purpose

Validate alerting, runbooks, on-call response, and error-budget process under controlled faults.

## Scenarios

| # | Scenario | Guide | Script |
|---|----------|-------|--------|
| 01 | Bad deploy rollback | [01-bad-deploy-rollback.md](01-bad-deploy-rollback.md) | — (Git revert + Argo sync) |
| 02 | Zone / pod failure | [02-zone-pod-failure.md](02-zone-pod-failure.md) | `scripts/game-days/inject-pod-failure.sh` |
| 03 | Redis / cart down | [03-redis-cart-down.md](03-redis-cart-down.md) | `scripts/game-days/inject-redis-down.sh` |
| 04 | Alert routing | [04-alert-routing.md](04-alert-routing.md) | [oncall/test-alerts.md](../oncall/test-alerts.md) |

## Prerequisites

- Phase 6 observability and PagerDuty live
- On-call roster notified
- Storefront baseline: https://boutique.biroltilki.art

## Success criteria

- Alert fires within expected SLO window
- On-call acknowledges in PagerDuty
- Runbook steps restore service
- Blameless notes captured for postmortem if gaps found

## Further reading

- [sre/runbooks/README.md](../runbooks/README.md)
- [setup/14-pagerduty.md](../../setup/14-pagerduty.md)
