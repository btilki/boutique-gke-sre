# Game day 04 — Alert routing

## Purpose

End-to-end verification that Cloud Monitoring alerts reach PagerDuty with correct severity and runbook links.

## When to use

After [setup/14-pagerduty.md](../../setup/14-pagerduty.md); before declaring production-ready.

## Prerequisites

- [oncall/test-alerts.md](../oncall/test-alerts.md)
- Notification channels in GCP project `boutique-gke`
- On-call schedule active in PagerDuty

## Architecture

```
Cloud Monitoring alert → notification channel → PagerDuty service → on-call engineer
```

Each policy documentation includes runbook URL under `docs/sre/runbooks/`.

## Step-by-step implementation

1. Follow [test-alerts.md](../oncall/test-alerts.md) for synthetic alert
2. Confirm PagerDuty incident created with runbook link
3. Acknowledge and resolve per playbook
4. Optionally trigger uptime check failure (brief) for `uptime-check-failed`
5. Document latency: fire → page → ack

## Validation

- PagerDuty incident visible on mobile/web
- Runbook URL opens correct markdown in GitHub/repo browser
- No alert black holes (test + prod channels)

## Troubleshooting

| Symptom         | Cause                | Fix                           |
| --------------- | -------------------- | ----------------------------- |
| No page         | Wrong channel        | Re-link PagerDuty integration |
| Duplicate pages | Overlapping policies | Deduplicate alert conditions  |

## Common mistakes

- Testing only email, not PagerDuty push
- Missing runbook URL in policy user labels

## Best practices

- Quarterly re-test routing
- Include secondary escalation path

## Production considerations

- Test alerts labeled `severity=test` to avoid SEV1 confusion

## Security considerations

- PagerDuty API keys in Secret Manager only

## Further reading

- [oncall/escalation.md](../oncall/escalation.md)
- [slos/catalog.md](../slos/catalog.md)
