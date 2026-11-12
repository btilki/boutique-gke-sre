# SRE documentation

Runbooks, SLOs, game days, on-call, and incident response for the closed production pilot.

| Path                                             | Description                                                                        |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- |
| [runbooks/](runbooks/)                           | Alert-linked runbooks (availability + latency burns, uptime, Redis, DR)            |
| [slos/](slos/)                                   | [catalog.md](slos/catalog.md), [burn-rate-alerting.md](slos/burn-rate-alerting.md) |
| [error-budget-policy.md](error-budget-policy.md) | Budget thresholds and freeze rules                                                 |
| [error-budget/](error-budget/)                   | Weekly review checklist + freeze log                                               |
| [capacity/](capacity/)                           | Capacity baseline + when-to-scale                                                  |
| [incident-response/](incident-response/)         | SEV1–SEV4, comms templates                                                         |
| [postmortems/](postmortems/)                     | Blameless postmortem template                                                      |
| [game-days/](game-days/)                         | Chaos scenarios                                                                    |
| [oncall/](oncall/)                               | On-call playbook                                                                   |

Rebuild path: [setup/README.md](../setup/README.md). Architecture: [overview.md](../architecture/overview.md).
