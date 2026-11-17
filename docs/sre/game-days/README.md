# Game days

Scheduled failure exercises for boutique-gke-sre SRE practice.

> **Closed reference (offline):** The cluster and public DNS are torn down. Guides and scripts remain for a rebuild. Only scenario **03** was executed on the lived path — see [reports/STATUS.md](reports/STATUS.md). Scenarios 01, 02, and 04 stay **Deferred** until topic 18 on a live cluster.

## Purpose

Validate alerting, runbooks, on-call response, and error-budget process under controlled faults.

## Scenarios

| #   | Scenario            | Guide                                                  | Script                                            | Execution status                       |
| --- | ------------------- | ------------------------------------------------------ | ------------------------------------------------- | -------------------------------------- |
| 01  | Bad deploy rollback | [01-bad-deploy-rollback.md](01-bad-deploy-rollback.md) | — (Git revert + Argo sync)                        | Deferred — [STATUS](reports/STATUS.md) |
| 02  | Zone / pod failure  | [02-zone-pod-failure.md](02-zone-pod-failure.md)       | `scripts/game-days/inject-pod-failure.sh`         | Deferred — [STATUS](reports/STATUS.md) |
| 03  | Redis / cart down   | [03-redis-cart-down.md](03-redis-cart-down.md)         | `scripts/game-days/inject-redis-down.sh`          | Executed                               |
| 04  | Alert routing       | [04-alert-routing.md](04-alert-routing.md)             | [oncall/test-alerts.md](../oncall/test-alerts.md) | Deferred — [STATUS](reports/STATUS.md) |

## Prerequisites

**While offline:** Do not expect storefront HTTPS, PagerDuty pages, or inject scripts to succeed. Use STATUS and dated reports as the source of truth.

**After rebuild (topic 18):**

- Phase 6 observability and PagerDuty live
- On-call roster notified
- Storefront baseline: `boutique.biroltilki.art`

## Success criteria

Ideal full run (record gaps when any item fails):

- Alert fires within expected SLO window
- On-call acknowledges in PagerDuty
- Runbook steps restore service
- Blameless notes captured for postmortem if gaps found

**Partial executes are valid.** Mark **Executed** in STATUS when a dated report exists; document incomplete criteria (for example GD03: PagerDuty and alert path not verified). Do not invent PagerDuty acks.

## After each execution

1. Fill [reports/TEMPLATE.md](reports/TEMPLATE.md) → dated file under `reports/`
2. Update [reports/STATUS.md](reports/STATUS.md) and the table below
3. Open a postmortem if action items warrant it

## Execution reports

| Scenario               | Report                                                   |
| ---------------------- | -------------------------------------------------------- |
| 03 — Redis / cart down | [Redis cart down](reports/2026-07-04-redis-cart-down.md) |

Full matrix: [reports/STATUS.md](reports/STATUS.md)

## Further reading

- [sre/runbooks/README.md](../runbooks/README.md)
- [setup/14-pagerduty.md](../../setup/14-pagerduty.md)
- [setup/18-sre-operability-game-days.md](../../setup/18-sre-operability-game-days.md) — topic 18
