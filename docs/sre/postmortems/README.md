# Postmortems

Blameless postmortem reports for incidents and game-day follow-ups.

## Template

- [TEMPLATE.md](TEMPLATE.md) — required sections for every report

## Completed reports

| Date       | Title                                                                 | Severity        | Source                                                                   |
| ---------- | --------------------------------------------------------------------- | --------------- | ------------------------------------------------------------------------ |
| 2026-07-04 | [Redis cart down — BA blocked restore](2026-07-04-redis-cart-down.md) | SEV2 (exercise) | [Game day 03 report](../game-days/reports/2026-07-04-redis-cart-down.md) |

## When to write one

- Unplanned SEV1–SEV2 incidents
- Game days that surface unexpected restore gaps or missed alert paths
- Error-budget exhaustion (per [error-budget-policy.md](../error-budget-policy.md))

Link new reports from [game-days/reports/STATUS.md](../game-days/reports/STATUS.md) when they originate from an exercise.
