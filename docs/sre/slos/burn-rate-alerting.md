# Multi-window burn-rate alerting

## Purpose

Define how Cloud Monitoring alert policies detect SLO error-budget burn using Google SRE multi-window, multi-burn-rate rules.

## When to use

- Implementing SLO alerts in Phase 6 ([setup/13-observability-slos.md](../../setup/13-observability-slos.md))
- Tuning alert noise after false positives
- On-call training and game day 04

## Prerequisites

- SLOs created in Cloud Monitoring ([catalog.md](catalog.md))
- Notification channel to PagerDuty configured
- Runbooks published under `docs/sre/runbooks/`

## Architecture

Burn-rate compares short-window SLI consumption to allowed budget. Fast burns page immediately; slow burns ticket before budget exhaustion.

```
SLI time series (Cloud Monitoring)
  → Alert policy (multi-window burn condition)
  → Notification channel (PagerDuty + runbook URL)
  → On-call acknowledges → runbook
```

## Burn-rate windows

| Window | Burn rate multiplier | Typical response   |
| ------ | -------------------- | ------------------ |
| 1h     | 14.4×                | Page — fast burn   |
| 6h     | 6×                   | Page               |
| 1d     | 3×                   | Ticket             |
| 3d     | 1×                   | Ticket — slow burn |

> **Cloud Monitoring API:** Maximum burn-rate lookback is **24 h**. Use a second **24 h / 1×** condition as the slow-burn ticket window when creating policies via API or `scripts/create-burn-rate-policies.sh`.

**Why multi-window:** A single long window misses fast outages; a single short window causes false pages during brief blips. Combining windows reduces false positives while catching real incidents ([Google SRE workbook](https://sre.google/workbook/alerting-on-slos/)).

## Alert policy → runbook mapping

| Alert policy name            | Runbook                                                                    |
| ---------------------------- | -------------------------------------------------------------------------- |
| `browse-availability-burn`   | [browse-availability-burn.md](../runbooks/browse-availability-burn.md)     |
| `checkout-availability-burn` | [checkout-availability-burn.md](../runbooks/checkout-availability-burn.md) |
| `uptime-check-failed`        | [uptime-check-failed.md](../runbooks/uptime-check-failed.md)               |

Every policy **must** include runbook URL in documentation or notification metadata, e.g.:

```
https://github.com/<org>/boutique-gke-sre/blob/main/docs/sre/runbooks/browse-availability-burn.md
```

## Step-by-step implementation

1. Create SLO in Cloud Monitoring for browse availability (99.9% / 30d)
2. Create alert policy using **SLO burn rate** condition
3. Add burn-rate thresholds for 1h and 6h (page), 1d and 3d (ticket)
4. Attach PagerDuty notification channel
5. Add runbook URL to policy user labels or documentation field
6. Repeat for checkout latency SLO
7. Test via [test-alerts.md](../oncall/test-alerts.md) or game day 04

## Validation

- Trigger synthetic burn or use test policy
- PagerDuty incident within 2 minutes
- Runbook link visible in incident

## Troubleshooting

| Symptom         | Cause                    | Fix                                |
| --------------- | ------------------------ | ---------------------------------- |
| No pages        | Threshold too high       | Lower burn multiplier on 1h window |
| Alert storm     | Missing multi-window AND | Require both short and long window |
| Missing runbook | Label not set            | Add `runbook_url` user label       |

## Common mistakes

- Alerting on raw metric without SLO object
- Same threshold for browse and checkout (different budgets)

## Best practices

- Start with workbook defaults; tune after one game day
- Document changes in postmortem when thresholds adjusted

## Production considerations

- Alert fatigue → on-call ignores pages; review monthly
- Error budget policy may freeze deploys while burns active ([error-budget-policy.md](../error-budget-policy.md))

## Security considerations

- PagerDuty keys in Secret Manager / Terraform, not Git

## Further reading

- [catalog.md](catalog.md)
- [Cloud Monitoring SLO alerts](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring#alerting_on_slo)
- [game-days/04-alert-routing.md](../game-days/04-alert-routing.md)
