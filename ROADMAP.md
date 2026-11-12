# Roadmap

Phased delivery for **boutique-gke-sre** — one phase per session: validate → commit → next.

**Full plan:** [docs/implementation/plan.md](docs/implementation/plan.md)
**Step-by-step guides:** [docs/setup/README.md](docs/setup/README.md) (pilot topics 01–16; optional after-rebuild scaffolds listed there)

| Phase   | Focus                                                 | Size | Status                            | Setup topics                                       |
| ------- | ----------------------------------------------------- | ---- | --------------------------------- | -------------------------------------------------- |
| **1**   | Repo scaffold + Terraform foundation                  | S    | ✅ Complete                       | 01–03                                              |
| **2**   | GKE + DNS + ingress + TLS                             | L    | ✅ Complete                       | 04–06                                              |
| **3**   | WIF + Artifact Registry + CI                          | M    | ✅ Complete                       | 07–08                                              |
| **4**   | Argo CD + policies + ESO + NetworkPolicy (**gate**)   | L    | ✅ Complete                       | 09–11                                              |
| **5**   | Online Boutique deploy                                | M    | ✅ Complete                       | 12                                                 |
| **6**   | Observability + SLOs                                  | L    | ✅ Complete                       | 13                                                 |
| **7**   | SRE ops + smoke validation                            | M    | ✅ Complete                       | 14–16                                              |
| **8**   | Teardown + backup/restore                             | M    | ✅ Complete                       | [teardown](docs/teardown.md)                       |
| **9-A** | Latency SLOs + burn alerts + Grafana dashboards       | M    | Optional scaffold (after rebuild) | [17](docs/setup/17-latency-slos-dashboards.md)     |
| **9-B** | HA GitOps, Argo uptime, game-day ops, GD03 postmortem | M    | Optional scaffold (after rebuild) | [18](docs/setup/18-sre-operability-game-days.md)   |
| **9-C** | Terraform monitoring + GKE Backup modules             | M    | Optional scaffold (after rebuild) | [19](docs/setup/19-monitoring-backup-terraform.md) |
| **9-D** | Error-budget ritual, capacity baseline, toil          | M    | Optional scaffold (after rebuild) | [20](docs/setup/20-sre-practices-capacity-toil.md) |

Phases 9-A–9-D are not part of the closed pilot. They appear only under [setup — Optional after rebuild](docs/setup/README.md#optional-after-rebuild--not-part-of-the-closed-pilot).

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
```

Optional after rebuild (scaffolds only): phases 9-A–9-D map to setup topics 17–20.

## Critical gate

**Do not skip Phase 4** before deploying Boutique.

## Current phase

**Phases 1–8 complete** — Infrastructure decommissioned. Git repository retained as the platform reference. See [docs/teardown.md](docs/teardown.md).

Optional follow-ups below are maintainer backlog, not lived pilot claims.

### Optional follow-ups

| Item                                    | Focus                                      | Notes                              |
| --------------------------------------- | ------------------------------------------ | ---------------------------------- |
| **C2**                                  | Migrate SLO + burn policies into Terraform | Not required for 9-C               |
| Chaos Mesh / custom-metrics HPA         | Architecture “future”                      | Beyond Phase 9-D                   |
| Slack budget bot / scheduled orphan GHA | Needs live integrations                    | Checklist + local scan exist today |

## Optional after rebuild — scaffold inventory (9-A–9-D)

Not part of the closed pilot. File map for maintainers; apply only via [setup optional section](docs/setup/README.md#optional-after-rebuild--not-part-of-the-closed-pilot).

### 9-A

| Area          | Path                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| Latency SLOs  | `observability/monitoring/slos/browse-latency.yaml`, `checkout-latency.yaml`         |
| Log metric    | `observability/monitoring/log-based-metrics/checkout-latency.yaml`                   |
| Burn alerts   | `observability/monitoring/alert-policies/*-latency-burn.yaml`                        |
| Create script | `scripts/create-latency-burn-rate-policies.sh`                                       |
| Runbooks      | `docs/sre/runbooks/browse-latency-burn.md`, `checkout-latency-burn.md`               |
| Grafana       | `observability/grafana/dashboards/` + provisioning                                   |
| Setup guide   | [docs/setup/17-latency-slos-dashboards.md](docs/setup/17-latency-slos-dashboards.md) |

### 9-B

| Area                 | Path                                                                                     |
| -------------------- | ---------------------------------------------------------------------------------------- |
| HPA / PDB / replicas | `gitops/apps/boutique/templates/hpa.yaml`, `pdb.yaml`, `values.yaml`                     |
| Argo CD uptime       | `observability/monitoring/uptime-checks/argocd-ui.yaml`                                  |
| Create script        | `scripts/create-argocd-uptime-check.sh`                                                  |
| Game-day ops         | `docs/sre/game-days/reports/{TEMPLATE,STATUS}.md`                                        |
| Postmortem           | `docs/sre/postmortems/2026-07-04-redis-cart-down.md`                                     |
| Setup guide          | [docs/setup/18-sre-operability-game-days.md](docs/setup/18-sre-operability-game-days.md) |

### 9-C

| Area              | Path                                                                                         |
| ----------------- | -------------------------------------------------------------------------------------------- |
| Monitoring module | `terraform/modules/monitoring/`                                                              |
| Backup module     | `terraform/modules/backup/`                                                                  |
| Env flags         | `enable_monitoring_iac`, `enable_backup_iac` in `environments/boutique`                      |
| Setup guide       | [docs/setup/19-monitoring-backup-terraform.md](docs/setup/19-monitoring-backup-terraform.md) |

### 9-D

| Area                       | Path                                                                                         |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| Weekly review + freeze log | `docs/sre/error-budget/`                                                                     |
| Freeze issue template      | `.github/ISSUE_TEMPLATE/error_budget_freeze.md`                                              |
| Capacity baseline          | `docs/sre/capacity/baseline.md`                                                              |
| Load stub                  | `scripts/load/smoke-browse.sh`                                                               |
| Orphan scan cadence        | `docs/operations/orphan-scan-cadence.md`                                                     |
| CI runbook-lint            | `.github/workflows/ci.yml`                                                                   |
| Setup guide                | [docs/setup/20-sre-practices-capacity-toil.md](docs/setup/20-sre-practices-capacity-toil.md) |
