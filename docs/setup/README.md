# Setup guides — boutique-gke-sre

Topic-based guides to bootstrap from an empty GCP project to production-ready URLs.

**Target DNS names** (inactive until rebuild — see [dns.md](../dns.md)):

- `boutique.biroltilki.art`
- `argocd.boutique.biroltilki.art`

## Execution order

| #   | Topic                                        | Guide                                                                      | Est.                | Phase                  |
| --- | -------------------------------------------- | -------------------------------------------------------------------------- | ------------------- | ---------------------- |
| 1   | GCP project and APIs                         | [01-gcp-project-apis.md](01-gcp-project-apis.md)                           | 30 min              | 1                      |
| 2   | Terraform remote state                       | [02-terraform-remote-state.md](02-terraform-remote-state.md)               | 45 min              | 1                      |
| 3   | VPC, subnets, Cloud NAT                      | [03-vpc-nat.md](03-vpc-nat.md)                                             | 1 h                 | 1                      |
| 4   | GKE cluster                                  | [04-gke-cluster.md](04-gke-cluster.md)                                     | 1–2 h               | 2                      |
| 5   | Cloud DNS + NS delegation                    | [05-cloud-dns.md](05-cloud-dns.md)                                         | 45 min              | 2                      |
| 6   | Static IP + TLS                              | [06-ingress-tls.md](06-ingress-tls.md)                                     | 1 h                 | 2                      |
| 7   | GitHub WIF                                   | [07-github-wif.md](07-github-wif.md)                                       | 1 h                 | 3                      |
| 8   | Artifact Registry + Binary Auth              | [08-artifact-registry-binary-auth.md](08-artifact-registry-binary-auth.md) | 1 h                 | 3                      |
| 9   | Argo CD bootstrap                            | [09-argocd-bootstrap.md](09-argocd-bootstrap.md)                           | 1 h                 | 4 **gate**             |
| 10  | ESO + Secret Manager                         | [10-external-secrets.md](10-external-secrets.md)                           | 45 min              | 4                      |
| 11  | Kyverno policies                             | [11-kyverno-policies.md](11-kyverno-policies.md)                           | 45 min              | 4                      |
| 12  | Boutique deploy                              | [12-boutique-deploy.md](12-boutique-deploy.md)                             | 1 h                 | 5                      |
| 13  | Observability + SLOs                         | [13-observability-slos.md](13-observability-slos.md)                       | 2 h                 | 6                      |
| 14  | PagerDuty                                    | [14-pagerduty.md](14-pagerduty.md)                                         | 1 h                 | 7                      |
| 15  | Cloud Armor                                  | [15-cloud-armor.md](15-cloud-armor.md)                                     | 45 min              | 7                      |
| 16  | Smoke + SRE verification                     | [16-smoke-validation.md](16-smoke-validation.md)                           | 1 h                 | 7–8                    |
| 17  | Latency SLOs + Grafana dashboards            | [17-latency-slos-dashboards.md](17-latency-slos-dashboards.md)             | 1–2 h               | **9-A** (post-rebuild) |
| 18  | SRE operability (HA, Argo uptime, game days) | [18-sre-operability-game-days.md](18-sre-operability-game-days.md)         | 1–2 h (+ game days) | **9-B** (post-rebuild) |
| 19  | Monitoring + Backup Terraform                | [19-monitoring-backup-terraform.md](19-monitoring-backup-terraform.md)     | 45–90 min           | **9-C** (post-rebuild) |
| 20  | SRE practices (budget, capacity, toil)       | [20-sre-practices-capacity-toil.md](20-sre-practices-capacity-toil.md)     | 30–60 min           | **9-D** (cadence)      |

Topics **01–16** are the original bootstrap path. Topics **17–20** are SRE expansions (Phases 9-A–9-D): repo artifacts are ready now; **apply / practice** per each guide (20 can be practiced offline).

All guides use the SETUP-GUIDE format: Goal, Why, Prerequisites, Commands, Expected output, Validation, Common problems, Recovery, Best practices, Security notes, Next step.

**Phase 4 gate:** Topics 09–11 (Argo CD, ESO, Kyverno) must complete before treating the cluster as production-ready or deploying Boutique (topic 12).

## Dependency graph

```
01 → 02 → 03 → 04 → 05 → 06
                ↓
07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16
                              ↓         ↓
                              ├→ 17 ←───┘   (latency SLOs)
                              ├→ 18 ←───┘   (HA + Argo uptime + game days)
                              ├→ 19 ←───┘   (TF monitoring + backup)
                              └→ 20         (practices — anytime; richer when live)
```

Topics 7–8 can start after topic 4 completes (parallel with 5–6). Topics 17–20 can run in flexible order after their prerequisites.

## Terraform phases

| Phase | Topics | Terraform modules applied                                                                |
| ----- | ------ | ---------------------------------------------------------------------------------------- |
| 1     | 01–03  | `project_apis`, `time_sleep` (API propagation), `networking` (use `-target` in topic 03) |
| 2     | 04–06  | `gke`, `ingress_edge`, `dns`                                                             |
| 3     | 07–08  | `wif`, `artifact_registry`, `binary_authorization`                                       |
| 4+    | 09–16  | GitOps / Console (Argo CD, ESO, Kyverno, observability, etc.)                            |
| 9-A   | 17     | Monitoring API / scripts (latency SLOs); Grafana via GitOps                              |
| 9-B   | 18     | GitOps HA sync + uptime scripts; game days on live cluster                               |
| 9-C   | 19     | `module.monitoring` / `module.backup` when `enable_*_iac=true`                           |
| 9-D   | 20     | Process + CI (no new Terraform required)                                                 |

## Related docs

- [Bootstrap summary](../bootstrap.md)
- [DNS reference](../dns.md)
- [Teardown](../teardown.md)
- [Roadmap](../../ROADMAP.md)

## Collaboration

You execute each guide step by step. Confirm completion before moving to the next topic.

After topic 16, see [bootstrap.md](../bootstrap.md). After a rebuild: topics [17](17-latency-slos-dashboards.md)–[20](20-sre-practices-capacity-toil.md).
