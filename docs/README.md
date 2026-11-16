# Documentation — boutique-gke-sre

Closed reference — see [`reference-claims.md`](reference-claims.md). These docs describe what was built and how to rebuild it.

If this file disagrees with [`setup/`](setup/README.md) on bootstrap steps, the setup guide wins.

---

## Where to start

Full map: [`../README.md`](../README.md#where-to-start).

| I want to…          | Read                                                                               |
| ------------------- | ---------------------------------------------------------------------------------- |
| See reference proof | [`reference-claims.md`](reference-claims.md) · [`evidence/`](evidence/README.md)   |
| Rebuild             | [`setup/`](setup/README.md) (topics 01–16) · [`teardown.md`](teardown.md)          |
| Operate day-2       | [`operations/`](operations/README.md) · [`sre/`](sre/README.md) · [`ci.md`](ci.md) |

---

## Guides by topic

| Topic                                  | Entry                                                                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Architecture summary                   | [`../ARCHITECTURE.md`](../ARCHITECTURE.md)                                                                               |
| Architecture deep dive                 | [`architecture/`](architecture/README.md)                                                                                |
| Design decisions                       | [`adr/`](adr/README.md)                                                                                                  |
| Reference claims                       | [`reference-claims.md`](reference-claims.md)                                                                             |
| Reference evidence                     | [`evidence/README.md`](evidence/README.md)                                                                               |
| Lessons learned                        | [`lessons-learned.md`](lessons-learned.md)                                                                               |
| Bootstrap summary                      | [`bootstrap.md`](bootstrap.md)                                                                                           |
| Bootstrap and teardown                 | [`setup/README.md`](setup/README.md) · [`teardown.md`](teardown.md)                                                      |
| DNS                                    | [`dns.md`](dns.md)                                                                                                       |
| CI contract                            | [`ci.md`](ci.md)                                                                                                         |
| Workflows and supply chain             | [`.github/workflows/README.md`](../.github/workflows/README.md) · [`security/supply-chain.md`](security/supply-chain.md) |
| Rollback                               | [`operations/rollback.md`](operations/rollback.md)                                                                       |
| Security and threat model              | [`security/README.md`](security/README.md)                                                                               |
| Day-2 operations                       | [`operations/README.md`](operations/README.md) · [`operations/operations-runbook.md`](operations/operations-runbook.md)  |
| Symptom troubleshooting                | [`troubleshooting/README.md`](troubleshooting/README.md)                                                                 |
| SLOs, runbooks, on-call, game days     | [`sre/README.md`](sre/README.md)                                                                                         |
| Release and upgrade                    | [`release/release-strategy.md`](release/release-strategy.md)                                                             |
| Implementation and phases (maintainer) | [`implementation/plan.md`](implementation/plan.md) · [`../ROADMAP.md`](../ROADMAP.md)                                    |

---

## Hostnames (when rebuilt)

| Service    | FQDN                             |
| ---------- | -------------------------------- |
| Storefront | `boutique.biroltilki.art`        |
| Argo CD    | `argocd.boutique.biroltilki.art` |

Both stay offline until you rebuild — no public A records. See [`dns.md`](dns.md).

---

## Repository meta

| File                                                       | Purpose                               |
| ---------------------------------------------------------- | ------------------------------------- |
| [`../README.md`](../README.md)                             | Project landing page                  |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md)                 | How to contribute                     |
| [`../SECURITY.md`](../SECURITY.md)                         | Security reporting and current limits |
| [`../PROJECT.md`](../PROJECT.md)                           | Charter and reference checklist       |
| [`../ROADMAP.md`](../ROADMAP.md)                           | Phase status                          |
| [`../CHANGELOG.md`](../CHANGELOG.md)                       | Notable changes                       |
| [`../REPOSITORY_STRUCTURE.md`](../REPOSITORY_STRUCTURE.md) | Full tree                             |

Sister platforms: [boutique-eks-gitops](https://github.com/btilki/boutique-eks-gitops) · [boutique-aks-devsecops](https://github.com/btilki/boutique-aks-devsecops)

Maintainer-only (skip on a first read): [`implementation/plan.md`](implementation/plan.md) · [`DOCUMENTATION.md`](DOCUMENTATION.md) · [`GUIDE_TEMPLATE.md`](GUIDE_TEMPLATE.md)
