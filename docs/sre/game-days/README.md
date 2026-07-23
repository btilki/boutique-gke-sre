# Game days

Scheduled failure exercises for boutique-gke-sre SRE practice.

## Purpose

Validate alerting, runbooks, on-call response, and error-budget process under controlled faults.

## Scenarios

| #   | Scenario            | Guide                                                  | Script                                            | Execution status                       |
| --- | ------------------- | ------------------------------------------------------ | ------------------------------------------------- | -------------------------------------- |
| 01  | Bad deploy rollback | [01-bad-deploy-rollback.md](01-bad-deploy-rollback.md) | — (Git revert + Argo sync)                        | Deferred — [STATUS](reports/STATUS.md) |
| 02  | Zone / pod failure  | [02-zone-pod-failure.md](02-zone-pod-failure.md)       | `scripts/game-days/inject-pod-failure.sh`         | Deferred — [STATUS](reports/STATUS.md) |
| 03  | Redis / cart down   | [03-redis-cart-down.md](03-redis-cart-down.md)         | `scripts/game-days/inject-redis-down.sh`          | Executed 2026-07-04                    |
| 04  | Alert routing       | [04-alert-routing.md](04-alert-routing.md)             | [oncall/test-alerts.md](../oncall/test-alerts.md) | Deferred — [STATUS](reports/STATUS.md) |

## Prerequisites

- Phase 6 observability and PagerDuty live
- On-call roster notified
- Storefront baseline: `boutique.biroltilki.art`

## Success criteria

- Alert fires within expected SLO window
- On-call acknowledges in PagerDuty
- Runbook steps restore service
- Blameless notes captured for postmortem if gaps found

## After each execution

1. Fill [reports/TEMPLATE.md](reports/TEMPLATE.md) → dated file under `reports/`
2. Update [reports/STATUS.md](reports/STATUS.md) and the table below
3. Open a postmortem if action items warrant it

## Execution reports

| Date       | Scenario               | Report                                                                 |
| ---------- | ---------------------- | ---------------------------------------------------------------------- |
| 2026-07-04 | 03 — Redis / cart down | [2026-07-04-redis-cart-down.md](reports/2026-07-04-redis-cart-down.md) |

Full matrix: [reports/STATUS.md](reports/STATUS.md)

## Further reading

- [sre/runbooks/README.md](../runbooks/README.md)
- [setup/14-pagerduty.md](../../setup/14-pagerduty.md)
- [setup/18-sre-operability-game-days.md](../../setup/18-sre-operability-game-days.md) — topic 18
