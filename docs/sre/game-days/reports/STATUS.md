# Game day execution status

Honest status of boutique-gke-sre failure exercises. Do **not** mark a scenario executed without a dated report under this directory.

| #   | Scenario            | Guide                              | Status                                        | Report                                                         | Notes                                                                                                     |
| --- | ------------------- | ---------------------------------- | --------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 01  | Bad deploy rollback | [01](../01-bad-deploy-rollback.md) | **Deferred** — needs live cluster             | —                                                              | Fill [TEMPLATE.md](TEMPLATE.md) after run                                                                 |
| 02  | Zone / pod failure  | [02](../02-zone-pod-failure.md)    | **Deferred** — needs live cluster             | —                                                              | Requires multi-replica / PDB credibility (GitOps HA)                                                      |
| 03  | Redis / cart down   | [03](../03-redis-cart-down.md)     | **Executed** 2026-07-04                       | [2026-07-04-redis-cart-down.md](2026-07-04-redis-cart-down.md) | PD/alert not verified; BA blocked restore — [postmortem](../../postmortems/2026-07-04-redis-cart-down.md) |
| 04  | Alert routing       | [04](../04-alert-routing.md)       | **Deferred** — needs live cluster + PagerDuty | —                                                              | Use [test-alerts.md](../../oncall/test-alerts.md)                                                         |

## Status definitions

| Status       | Meaning                                                                |
| ------------ | ---------------------------------------------------------------------- |
| **Executed** | Live inject (or approved tabletop) with dated report committed         |
| **Deferred** | Guide exists; run blocked until cluster rebuild / topic 18             |
| **Partial**  | Run happened but success criteria incomplete (document gaps in report) |

Scenario 03 is **Executed** with known gaps (PagerDuty not exercised). Re-run after rebuild may move gaps to a new report row.

## After each run

1. Copy [TEMPLATE.md](TEMPLATE.md) → `YYYY-MM-DD-<slug>.md`
2. Add row to [README.md](README.md)
3. Update this STATUS table
4. If gaps warrant: open postmortem from [postmortems/TEMPLATE.md](../../postmortems/TEMPLATE.md) (example: [2026-07-04-redis-cart-down.md](../../postmortems/2026-07-04-redis-cart-down.md))

## Related

- [Game days index](../README.md)
- [Setup topic 18](../../../setup/18-sre-operability-game-days.md) — topic 18 apply path
- [ROADMAP.md](../../../../ROADMAP.md) — Phase 9-B
