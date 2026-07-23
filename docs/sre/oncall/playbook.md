# On-call playbook

## Purpose

Step-by-step flow when a PagerDuty page fires for boutique-gke-sre.

## When to use

- Any production alert during on-call shift
- Training for new on-call engineers

## Prerequisites

- [oncall/README.md](README.md) shift checklist complete
- Runbook URL from alert payload or [runbooks/README.md](../runbooks/README.md)

## Architecture

Alert → acknowledge → triage → mitigate → communicate → resolve → follow-up.

## Step-by-step implementation

1. **Acknowledge** PagerDuty incident within 5 minutes
2. **Assess severity** using [severity.md](../incident-response/severity.md)
3. **Open runbook** linked from alert (e.g. `browse-availability-burn`)
4. **Triage user impact:** `curl -I `boutique.biroltilki.art``; test checkout
5. **Check recent changes:** Argo CD sync history, last merged PR
6. **Mitigate** per runbook (rollback, scale, restore Redis, etc.)
7. **Communicate** per [comms.md](../incident-response/comms.md) if SEV2+
8. **Resolve** when SLO recovered; note timeline in PagerDuty
9. **Follow-up:** postmortem template for SEV1–SEV2

## Validation

- Storefront and checkout paths healthy
- Alert auto-resolves or manually resolved with reason
- No ongoing burn on primary SLO

## Troubleshooting

| Symptom          | Cause               | Fix                                           |
| ---------------- | ------------------- | --------------------------------------------- |
| Flapping alert   | Threshold too tight | Tune after incident; temporary mute with care |
| Runbook mismatch | Renamed policy      | Update Cloud Monitoring user labels           |

## Common mistakes

- Deep debugging before user-impact assessment
- Closing incident before metrics green

## Best practices

- One incident commander for SEV1
- Capture `kubectl get events` early

## Production considerations

- Prefer Git revert over in-cluster patches
- Document manual Argo CD sync in incident log

## Security considerations

- Do not paste secrets in PagerDuty notes

## Further reading

- [escalation.md](escalation.md)
- [test-alerts.md](test-alerts.md)
