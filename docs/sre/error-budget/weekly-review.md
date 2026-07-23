# Weekly error-budget review

Fill this checklist in the weekly platform sync (or async). Policy: [../error-budget-policy.md](../error-budget-policy.md).

**Week of (UTC):** YYYY-MM-DD
**Reviewer(s):**
**On-call:**

## 1. Snapshot (Cloud Monitoring → SLOs)

| SLO                   | Target         | Remaining budget % | Band (normal / cautious / freeze / exhausted) |
| --------------------- | -------------- | ------------------ | --------------------------------------------- |
| Browse availability   | 99.9%          |                    |                                               |
| Browse latency        | p95 &lt; 500ms |                    |                                               |
| Checkout availability | 99.95%         |                    |                                               |
| Checkout latency      | p95 &lt; 1s    |                    |                                               |

**Strictest band this week:** ________________

## 2. Burn / incidents

| Item                       | Notes                                                 |
| -------------------------- | ----------------------------------------------------- |
| Fast-burn pages this week? | Y/N — which policies?                                 |
| Slow-burn tickets?         | Y/N                                                   |
| SEV1–SEV2 opened?          | Link issues / postmortems                             |
| Game days this week?       | Link [reports/STATUS](../game-days/reports/STATUS.md) |

## 3. Decision

| Remaining (worst SLO) | Action                                                                                                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| &gt; 50%              | Normal velocity                                                                                                                          |
| 25–50%                | Cautious — note extra reviewers / deferred risky work                                                                                    |
| &lt; 25%              | Freeze — open [error_budget_freeze](../../../.github/ISSUE_TEMPLATE/error_budget_freeze.md) issue; append [freeze-log.md](freeze-log.md) |
| 0%                    | SEV2 + freeze + reliability sprint                                                                                                       |

**Decision this week:** normal / cautious / freeze / SEV2

**Exceptions approved (security/hotfix):** none / ________________

## 4. Deploy / change look-ahead

- Risky changes planned (infra, BA, Kyverno, digest flood)? ________________
- Allowed under current band? Y/N

## 5. Close-out

- [ ] Comms sent if cautious/freeze (template in [error-budget-policy.md](../error-budget-policy.md))
- [ ] Freeze log updated if entering/exiting freeze
- [ ] Next review date: ________________

## Links

- [SLO catalog](../slos/catalog.md)
- [Day-2 ops](../../operations/day-2-ops.md)
- [On-call](../oncall/README.md)
