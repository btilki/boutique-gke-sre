# On-call escalation

## Purpose

Define when and how to escalate beyond the primary on-call engineer.

## When to use

- SEV1/SEV2 incidents
- Primary unavailable or stuck > 15 minutes
- Security or data-integrity concerns

## Prerequisites

- PagerDuty escalation policy configured
- [severity.md](../incident-response/severity.md) understood

## Escalation matrix

| Severity | Condition | Escalate to | Target time |
|----------|-----------|-------------|-------------|
| SEV1 | Checkout down or data loss risk | Secondary + platform lead | Immediate |
| SEV2 | Browse degraded > 15 min | Secondary on-call | 15 min |
| SEV3 | Single service degraded, workaround exists | Primary continues; notify secondary | 30 min if unresolved |
| SEV4 | Low impact / internal | No page escalation | — |

## Steps

1. Primary acknowledges and attempts runbook mitigation
2. If no improvement in matrix window → **escalate** in PagerDuty (next level)
3. Platform lead joins bridge for SEV1; comms owner assigned
4. Document decision points in incident timeline
5. After resolution, schedule postmortem for SEV1–SEV2

## Validation

- Escalation policy test in PagerDuty shows correct order
- Secondary received page during game day 04

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Escalation loop | Circular policy | Fix PagerDuty schedule |
| Wrong person paged | Outdated roster | Update PD schedule |

## Common mistakes

- Waiting too long on SEV1 checkout outage
- Escalating without summary for next responder

## Best practices

- Handoff includes: impact, actions taken, current hypothesis
- Use [comms.md](../incident-response/comms.md) templates

## Production considerations

- GCP support case for regional GKE control plane issues (SEV1)

## Security considerations

- Involve security for suspected compromise before destructive recovery

## Further reading

- [playbook.md](playbook.md)
- [game-days/04-alert-routing.md](../game-days/04-alert-routing.md)
