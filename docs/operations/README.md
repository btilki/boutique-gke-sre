# Operations documentation

Day-2 operations guides for the boutique-gke-sre production reference environment.

| Document                                           | Description                                                                                                                                             |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [quick-reference.md](quick-reference.md)           | **One-page on-call card** (printable)                                                                                                                   |
| **[operations-runbook.md](operations-runbook.md)** | **Canonical production runbook** — deploy, rollback, scaling, DR, backup/restore, incident response, monitoring, maintenance, rotation, troubleshooting |
| [day-2-ops.md](day-2-ops.md)                       | Recurring operational cadence (weekly/monthly/quarterly)                                                                                                |
| [rollback.md](rollback.md)                         | GitOps rollback patterns (summary; detail in runbook)                                                                                                   |

## Runbook sections

The [operations runbook](operations-runbook.md) covers:

- Overview, Deployment, Rollback, Scaling
- Disaster Recovery, Backup, Restore
- Incident Response, Health Checks
- Monitoring, Alerting, Logging
- Maintenance, Upgrades
- Certificate Rotation, Secret Rotation
- Troubleshooting, Common incidents, Recovery procedures
- Postmortem checklist, Automation opportunities

Each section includes: **Purpose**, **Commands**, **Validation**, **Expected outcome**, **Recovery steps**, **Best practices**.

## Related documentation

| Area                  | Path                                                                 |
| --------------------- | -------------------------------------------------------------------- |
| Alert-linked runbooks | [docs/sre/runbooks/](../sre/runbooks/)                               |
| On-call               | [docs/sre/oncall/](../sre/oncall/)                                   |
| Incident severity     | [docs/sre/incident-response/](../sre/incident-response/)             |
| Architecture          | [docs/architecture/overview.md](../architecture/overview.md)         |
| Smoke validation      | [docs/setup/16-smoke-validation.md](../setup/16-smoke-validation.md) |
| Teardown              | [docs/teardown.md](../teardown.md)                                   |
