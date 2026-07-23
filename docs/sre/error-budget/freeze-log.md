# Error-budget freeze log

Append-only record of cautious/freeze/SEV2 decisions. Policy: [../error-budget-policy.md](../error-budget-policy.md).

Do **not** delete rows. When a freeze ends, add an **Exit** row referencing the same freeze ID.

## Active / historical entries

| Freeze ID | Entered (UTC)     | Exited (UTC)      | Band   | Worst SLO + % remaining   | Declared by   | GitHub issue | Notes                                 |
| --------- | ----------------- | ----------------- | ------ | ------------------------- | ------------- | ------------ | ------------------------------------- |
| _example_ | 2026-01-01T12:00Z | 2026-01-03T18:00Z | freeze | checkout-availability 18% | platform-lead | #N           | Reliability sprint; digest PRs paused |
|           |                   |                   |        |                           |               |              |                                       |

## How to use

1. Budget &lt; 25% or 0% → open issue from [.github/ISSUE_TEMPLATE/error_budget_freeze.md](../../../.github/ISSUE_TEMPLATE/error_budget_freeze.md)
2. Add a row here with a new **Freeze ID** (`EB-YYYYMMDD-N`)
3. On recovery (&gt; 25% + platform lead sign-off): set **Exited**, close the issue, note resume of normal velocity
4. Link related postmortems under Notes

## Related

- [weekly-review.md](weekly-review.md)
- [incident-response/severity.md](../incident-response/severity.md)
