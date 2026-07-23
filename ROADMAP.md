# Roadmap

Phased delivery for **boutique-gke-sre** — one phase per session: validate → commit → next.

**Full plan:** [docs/implementation/plan.md](docs/implementation/plan.md)
**Step-by-step guides:** [docs/setup/README.md](docs/setup/README.md) (topics 01–20)

| Phase   | Focus                                                 | Size | Status                                               | Setup topics                                       |
| ------- | ----------------------------------------------------- | ---- | ---------------------------------------------------- | -------------------------------------------------- |
| **1**   | Repo scaffold + Terraform foundation                  | S    | ✅ Complete                                          | 01–03                                              |
| **2**   | GKE + DNS + ingress + TLS                             | L    | ✅ Complete                                          | 04–06                                              |
| **3**   | WIF + Artifact Registry + CI                          | M    | ✅ Complete                                          | 07–08                                              |
| **4**   | Argo CD + policies + ESO + NetworkPolicy (**gate**)   | L    | ✅ Complete                                          | 09–11                                              |
| **5**   | Online Boutique deploy                                | M    | ✅ Complete                                          | 12                                                 |
| **6**   | Observability + SLOs                                  | L    | ✅ Complete                                          | 13                                                 |
| **7**   | SRE ops + smoke validation                            | M    | ✅ Complete                                          | 14–16                                              |
| **8**   | Teardown + backup/restore                             | M    | ✅ Complete                                          | [teardown](docs/teardown.md)                       |
| **9-A** | Latency SLOs + burn alerts + Grafana dashboards       | M    | ✅ Repo ready (apply on rebuild)                     | [17](docs/setup/17-latency-slos-dashboards.md)     |
| **9-B** | HA GitOps, Argo uptime, game-day ops, GD03 postmortem | M    | ✅ Repo ready (apply / execute on rebuild)           | [18](docs/setup/18-sre-operability-game-days.md)   |
| **9-C** | Terraform monitoring + GKE Backup modules             | M    | ✅ Repo ready (enable flags on rebuild)              | [19](docs/setup/19-monitoring-backup-terraform.md) |
| **9-D** | Error-budget ritual, capacity baseline, toil          | M    | ✅ Repo ready (cadence anytime / live after rebuild) | [20](docs/setup/20-sre-practices-capacity-toil.md) |

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
                              └──────────→ 9-A (topic 17)
                              └──────────→ 9-B (topic 18)
                              └──────────→ 9-C (topic 19)
                              └──────────→ 9-D (topic 20; practice layer)
```

## Critical gate

**Do not skip Phase 4** before treating the cluster as production-ready.

## Current phase

**Phases 1–8 complete** — Infrastructure decommissioned 2026-07-04. Git repository retained as the platform reference. See [docs/teardown.md](docs/teardown.md).

**Phases 9-A–9-D — repo ready:** Apply/execute topics **17–20** on rebuild (topic 20 cadence can be practiced offline). Optional follow-ups below.

### Optional follow-ups

| Item                                    | Focus                                      | Notes                              |
| --------------------------------------- | ------------------------------------------ | ---------------------------------- |
| **C2**                                  | Migrate SLO + burn policies into Terraform | Not required for 9-C               |
| Chaos Mesh / custom-metrics HPA         | Architecture “future”                      | Beyond Phase 9-D                   |
| Slack budget bot / scheduled orphan GHA | Needs live integrations                    | Checklist + local scan exist today |

## Phase 9-A deliverables (9-A)

| Area          | Path                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| Latency SLOs  | `observability/monitoring/slos/browse-latency.yaml`, `checkout-latency.yaml`         |
| Log metric    | `observability/monitoring/log-based-metrics/checkout-latency.yaml`                   |
| Burn alerts   | `observability/monitoring/alert-policies/*-latency-burn.yaml`                        |
| Create script | `scripts/create-latency-burn-rate-policies.sh`                                       |
| Runbooks      | `docs/sre/runbooks/browse-latency-burn.md`, `checkout-latency-burn.md`               |
| Grafana       | `observability/grafana/dashboards/` + provisioning                                   |
| Setup guide   | [docs/setup/17-latency-slos-dashboards.md](docs/setup/17-latency-slos-dashboards.md) |

## Phase 9-B deliverables (9-B)

| Area                 | Path                                                                                     |
| -------------------- | ---------------------------------------------------------------------------------------- |
| HPA / PDB / replicas | `gitops/apps/boutique/templates/hpa.yaml`, `pdb.yaml`, `values.yaml`                     |
| Argo CD uptime       | `observability/monitoring/uptime-checks/argocd-ui.yaml`                                  |
| Create script        | `scripts/create-argocd-uptime-check.sh`                                                  |
| Game-day ops         | `docs/sre/game-days/reports/{TEMPLATE,STATUS}.md`                                        |
| Postmortem           | `docs/sre/postmortems/2026-07-04-redis-cart-down.md`                                     |
| Setup guide          | [docs/setup/18-sre-operability-game-days.md](docs/setup/18-sre-operability-game-days.md) |

## Phase 9-C deliverables (9-C)

| Area              | Path                                                                                         |
| ----------------- | -------------------------------------------------------------------------------------------- |
| Monitoring module | `terraform/modules/monitoring/`                                                              |
| Backup module     | `terraform/modules/backup/`                                                                  |
| Env flags         | `enable_monitoring_iac`, `enable_backup_iac` in `environments/boutique`                      |
| Setup guide       | [docs/setup/19-monitoring-backup-terraform.md](docs/setup/19-monitoring-backup-terraform.md) |

## Phase 9-D deliverables (9-D)

| Area                       | Path                                                                                         |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| Weekly review + freeze log | `docs/sre/error-budget/`                                                                     |
| Freeze issue template      | `.github/ISSUE_TEMPLATE/error_budget_freeze.md`                                              |
| Capacity baseline          | `docs/sre/capacity/baseline.md`                                                              |
| Load stub                  | `scripts/load/smoke-browse.sh`                                                               |
| Orphan scan cadence        | `docs/operations/orphan-scan-cadence.md`                                                     |
| CI runbook-lint            | `.github/workflows/ci.yml`                                                                   |
| Setup guide                | [docs/setup/20-sre-practices-capacity-toil.md](docs/setup/20-sre-practices-capacity-toil.md) |
