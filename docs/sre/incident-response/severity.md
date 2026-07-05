# Incident severity (SEV1–SEV4)

## Purpose

Standardize incident classification, response expectations, and escalation for boutique-gke-sre on-call.

## When to use

- Triaging PagerDuty incidents
- Declaring error-budget exhaustion (SEV2)
- Writing postmortems and game-day reports

## Prerequisites

- On-call rotation configured ([oncall/README.md](../oncall/README.md))
- Familiarity with SLOs ([slos/catalog.md](../slos/catalog.md))

## Architecture

Severity drives response time, communication breadth, and postmortem requirement. Cloud Monitoring alerts should document severity in policy name or labels.

```
Alert / user report → classify SEV → response playbook → comms → resolve → postmortem (SEV1–2)
```

## Severity definitions

| Severity | Definition                                  | Response                        | Examples                                              |
| -------- | ------------------------------------------- | ------------------------------- | ----------------------------------------------------- |
| **SEV1** | Complete outage or data loss risk           | Immediate page; war room        | `boutique.biroltilki.art` down; checkout 100% failing |
| **SEV2** | Major degradation or error budget exhausted | Page on-call; stakeholder comms | Checkout SLO fast burn; budget at 0%                  |
| **SEV3** | Partial degradation; workaround exists      | Ticket; business-hours response | Elevated 5xx on one service; cart flaky               |
| **SEV4** | Minor; no user impact                       | Backlog                         | Dashboard gap; test alert; doc typo                   |

## Error budget linkage

Remaining error budget at **0%** → treat as **SEV2** minimum per [error-budget-policy.md](../error-budget-policy.md).

## Step-by-step implementation

1. Acknowledge PagerDuty incident within 5 minutes (SEV1–2)
2. Classify using table above; update incident title with `SEVn`
3. Open matching runbook from `docs/sre/runbooks/`
4. Post initial comms if SEV1–2 ([comms.md](comms.md))
5. Escalate per [oncall/escalation.md](../oncall/escalation.md) if not mitigated in SLA
6. Resolve; document timeline; postmortem for SEV1–2

## Validation

- Tabletop: given scenario, on-call picks correct SEV in &lt; 2 minutes
- Game day 04 validates alert → severity → runbook path

## Troubleshooting

| Symptom                 | Cause         | Fix                         |
| ----------------------- | ------------- | --------------------------- |
| Everything labeled SEV1 | Alert fatigue | Tune burn thresholds        |
| Under-classification    | Culture       | On-call lead reviews weekly |

## Common mistakes

- SEV1 without customer impact evidence
- Skipping postmortem on repeated SEV3s

## Best practices

- Blameless postmortems for SEV1–2 within 5 business days
- Align alert policy names with runbooks

## Production considerations

- Realistic SEV discipline builds on-call muscle memory even on smaller platforms

## Security considerations

- SEV1 data-loss scenarios include secret exposure — invoke security lead

## Further reading

- [comms.md](comms.md)
- [postmortems/TEMPLATE.md](../postmortems/TEMPLATE.md)
- [oncall/escalation.md](../oncall/escalation.md)
