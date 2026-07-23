# Error budget policy

## Purpose

Define how the team responds as monthly SLO error budget is consumed — from normal velocity through freeze and SEV2 incident.

## When to use

- SLO burn alerts fire or dashboard shows budget trend
- Planning risky deploys (infra, digest promotion, game days)
- Weekly platform sync / monthly reliability review

## Prerequisites

- SLOs defined in [slos/catalog.md](slos/catalog.md)
- Severity taxonomy in [incident-response/severity.md](incident-response/severity.md)
- On-call rotation active
- Living artifacts: [error-budget/weekly-review.md](error-budget/weekly-review.md), [error-budget/freeze-log.md](error-budget/freeze-log.md)

## Architecture

Error budget is the complement of SLO target over a rolling window. Burn-rate alerts consume budget faster than steady-state errors. This policy connects budget % to engineering behavior.

```
Cloud Monitoring SLO → remaining budget %
  → >50% normal | 25–50% cautious | <25% freeze | 0% SEV2
```

## Thresholds and responses

| Remaining budget   | Engineering response                                          |
| ------------------ | ------------------------------------------------------------- |
| **> 50%**          | Normal velocity — deploys with standard PR + manual Argo sync |
| **25–50%**         | Cautious — reduce risky changes; extra reviewer for infra     |
| **< 25%**          | **Freeze** non-critical deploys; reliability work prioritized |
| **0% (exhausted)** | **SEV2** — halt feature releases; reliability sprint          |

## Roles

| Role              | Responsibility                                                    |
| ----------------- | ----------------------------------------------------------------- |
| **On-call**       | Declares current budget band during incidents; pages per severity |
| **Platform lead** | Approves exceptions to freeze; owns reliability sprint scope      |
| **All engineers** | No discretionary production sync during freeze without approval   |

## Communication template

When entering **cautious** or **freeze**:

```
Subject: [boutique-gke] Error budget — <cautious|freeze>

Browse/checkout SLO budget at <X>% remaining (<30d window).
Action: <normal|cautious|freeze> per error-budget-policy.md
On-call: <name> | Platform lead: <name>
Next update: <UTC time>
```

Full incident template: [incident-response/comms.md](incident-response/comms.md).

## Step-by-step implementation

1. Each week: fill [error-budget/weekly-review.md](error-budget/weekly-review.md) (platform sync)
2. Open Cloud Monitoring → SLOs → browse and checkout SLOs
3. Note **Remaining error budget** percentage; map to threshold table above
4. Post to team channel if cautious or freeze (comms template above)
5. If &lt; 25%: open GitHub issue from [.github/ISSUE_TEMPLATE/error_budget_freeze.md](../../.github/ISSUE_TEMPLATE/error_budget_freeze.md); append [error-budget/freeze-log.md](error-budget/freeze-log.md)
6. If 0%: open SEV2, stop non-reliability deploys, schedule postmortem
7. Resume normal velocity only after budget recovers above 25% with platform lead sign-off (exit freeze log + close issue)

## Validation

- Weekly: checklist completed; freeze log matches any open freeze issues
- Monthly: budget consumption vs deploy log correlates
- Game day 01 triggers burn → team follows rollback, not feature work

## Troubleshooting

| Symptom                | Cause                 | Fix                                             |
| ---------------------- | --------------------- | ----------------------------------------------- |
| Budget shows N/A       | Insufficient SLI data | Wait for SLO window; check metrics              |
| Disagreement on freeze | Ambiguous band        | Platform lead decision documented in freeze-log |

## Common mistakes

- Ignoring budget because the environment is non-production — practice prod discipline
- Continuing game days during freeze without lead approval
- Declaring freeze in chat without freeze-log + issue

## Best practices

- Review budget via [weekly-review.md](error-budget/weekly-review.md) every week
- Tie deploy freeze to explicit exit criteria in the freeze issue
- Keep freeze-log append-only

## Production considerations

- 99.9% browse ≈ 43.2 min downtime/month; 99.95% checkout ≈ 21.6 min
- Freeze reduces change risk but does not auto-remediate — runbooks still required

## Security considerations

- Emergency security patches may bypass freeze with platform lead + documented exception (freeze issue + freeze-log Notes)

## Further reading

- [error-budget/README.md](error-budget/README.md)
- [slos/catalog.md](slos/catalog.md)
- [burn-rate-alerting.md](slos/burn-rate-alerting.md)
- [severity.md](incident-response/severity.md)
- [setup/20-sre-practices-capacity-toil.md](../setup/20-sre-practices-capacity-toil.md) (topic 20)
