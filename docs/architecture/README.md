# Architecture — boutique-gke-sre

Production pilot closed. GCP resources from the pilot were destroyed. These pages describe the design as it exists in Git. They do not provision GCP.

If you skipped the summary, start here: [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md).

---

## How to use this folder

| I want to…                        | Read first                                                                                                         |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Follow CI → Git → Argo → Boutique | [overview.md §7](overview.md#7-deployment-flow) · [`../ci.md`](../ci.md)                                           |
| Understand security boundaries    | [overview.md §9](overview.md#9-security-boundaries) · [`../security/threat-model.md`](../security/threat-model.md) |
| See metrics, SLOs, alerts         | [overview.md §13](overview.md#13-observability-signal-ownership) · [`../sre/`](../sre/README.md)                   |
| Judge cost and failure modes      | [overview.md §10](overview.md#10-failure-scenarios) · [§14](overview.md#14-cost-considerations)                    |
| Walk requirements and constraints | [overview.md §1](overview.md#1-requirements) · [§2](overview.md#2-constraints)                                     |
| Network and ingress               | [overview.md §8](overview.md#8-network-flow) · [`../dns.md`](../dns.md)                                            |

Pilot claims (no cluster required): [`../pilot-claims.md`](../pilot-claims.md)
Delivery contracts: [`../ci.md`](../ci.md) · [`../operations/rollback.md`](../operations/rollback.md)

---

## Architecture pages

| Doc                                              | Purpose                           |
| ------------------------------------------------ | --------------------------------- |
| [overview.md](overview.md)                       | Canonical deep dive (16 sections) |
| [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) | Executive summary                 |

When implementation changes the system, update `overview.md` and relevant ADRs in the same PR.

---

## Architecture Decision Records

| ADR                                     | Decision                       |
| --------------------------------------- | ------------------------------ |
| [001](../adr/001-single-cluster.md)     | Single GCP project and cluster |
| [002](../adr/002-wif-over-sa-keys.md)   | WIF over service account keys  |
| [003](../adr/003-manual-argocd-sync.md) | Manual Argo CD sync            |

Full ADR index: [`../adr/README.md`](../adr/README.md)

---

## Maturity

This is a production pilot: real SRE and supply-chain controls on one GKE cluster. It does not claim multi-region HA or enterprise-scale DR.

---

## Related

- [`../README.md`](../README.md) — documentation index
- [`../setup/README.md`](../setup/README.md) — rebuild (topics 01–16)
- [`../../ROADMAP.md`](../../ROADMAP.md) — phase status
- [`../implementation/plan.md`](../implementation/plan.md) — maintainer plan
