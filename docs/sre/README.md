# SRE documentation

**SRE** (**Site Reliability Engineering**) runbooks, **SLOs** (**Service Level Objectives**), game days, on-call, and incident response.

| Path                                             | Description                                                                        |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- |
| [runbooks/](runbooks/)                           | Alert-linked runbooks (availability + latency burns, uptime, Redis, DR)            |
| [slos/](slos/)                                   | [catalog.md](slos/catalog.md), [burn-rate-alerting.md](slos/burn-rate-alerting.md) |
| [error-budget-policy.md](error-budget-policy.md) | Budget thresholds and freeze rules                                                 |
| [error-budget/](error-budget/)                   | Weekly review checklist + freeze log                                               |
| [capacity/](capacity/)                           | Capacity baseline + when-to-scale                                                  |
| [incident-response/](incident-response/)         | SEV1–SEV4, comms templates                                                         |
| [postmortems/](postmortems/)                     | Blameless postmortem template                                                      |
| [game-days/](game-days/)                         | Chaos scenarios (Phase 7)                                                          |
| [oncall/](oncall/)                               | On-call playbook (Phase 7)                                                         |

**Phase 9-A:** Latency SLOs, burn alerts, runbooks, Grafana — apply via [setup/17-latency-slos-dashboards.md](../setup/17-latency-slos-dashboards.md).

**Phase 9-B:** HA GitOps, Argo uptime, game-day TEMPLATE/STATUS, GD03 postmortem — apply/execute via [setup/18-sre-operability-game-days.md](../setup/18-sre-operability-game-days.md).

**Phase 9-C:** Terraform monitoring + GKE Backup modules — enable via [setup/19-monitoring-backup-terraform.md](../setup/19-monitoring-backup-terraform.md).

**Phase 9-D:** Error-budget ritual, capacity baseline, toil — practice via [setup/20-sre-practices-capacity-toil.md](../setup/20-sre-practices-capacity-toil.md).

See [ROADMAP.md](../../ROADMAP.md).

Architecture reference: [overview.md](../architecture/overview.md)
