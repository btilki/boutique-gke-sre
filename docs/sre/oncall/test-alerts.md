# Test alerts

## Purpose

Verify PagerDuty and Cloud Monitoring notification routing before relying on production on-call.

## When to use

- After PagerDuty setup ([setup/14-pagerduty.md](../../setup/14-pagerduty.md))
- Start of new on-call rotation (optional)
- Game day 04 — alert routing

## Prerequisites

- Editor access to Cloud Monitoring in `boutique-gke`
- PagerDuty service linked to notification channel
- Mobile push enabled for on-call user

## Architecture

Synthetic alert or uptime check exercises the same channel path as production burn-rate alerts.

## Step-by-step implementation

1. Cloud Console → Monitoring → Alerting → **Create policy**
2. Add condition: **Metric threshold** on a test metric OR use **Uptime check** on internal test path
3. Set notification channel → PagerDuty boutique service
4. Add user label: `runbook_url=https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/oncall/test-alerts.md`
5. Set `severity=test` in documentation or display name
6. Trigger condition (or use **TEST NOTIFICATION** on channel if available)
7. Confirm push/SMS/email on on-call device
8. Acknowledge and resolve in PagerDuty
9. Delete or disable test policy after success

## Validation

- Incident appears in PagerDuty within 2 minutes of trigger
- Runbook link visible in incident details
- No duplicate pages to non-on-call users

## Troubleshooting

| Symptom       | Cause                 | Fix                                  |
| ------------- | --------------------- | ------------------------------------ |
| No incident   | Integration key wrong | Re-create PD notification channel    |
| Delay > 5 min | Aggregation window    | Lower alignment period for test only |

## Common mistakes

- Leaving test policy enabled with production-like thresholds
- Testing email only, not push

## Best practices

- Name policies `TEST-*` clearly
- Record test date in on-call handoff log

## Production considerations

- Run during business hours first
- Coordinate with game day 04 for full burn-rate test

## Security considerations

- PD integration keys stored in Secret Manager / Terraform, not Git

## Further reading

- [oncall/README.md](README.md)
- [game-days/04-alert-routing.md](../game-days/04-alert-routing.md)
