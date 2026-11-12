# Setup guides — boutique-gke-sre

Audience: Implementer
Authority: This directory is the **single source of truth** for bootstrap. If README, chat, or scripts conflict with `docs/setup/`, this guide wins.
[Doc index](../README.md) · [Architecture summary](../../ARCHITECTURE.md) · [Roadmap](../../ROADMAP.md)

> **Pilot status:** Production pilot closed. Topics 01–16 and Phase 8 teardown completed.
> There is no live GKE cluster or public DNS from that run.
> This guide is for step-by-step rebuild and validation. Follow topics 01 → 16 in order unless you abort early (still use [teardown.md](../teardown.md)).
> Do not assume a cluster already exists because the repo is complete in Git.

**Target DNS names** (offline until rebuild — see [dns.md](../dns.md)):

- `boutique.biroltilki.art`
- `argocd.boutique.biroltilki.art`

---

## Topic sequence (pilot path: 01–16)

| #   | Topic                           | Guide                                                                      | Est.   | Phase      | Status |
| --- | ------------------------------- | -------------------------------------------------------------------------- | ------ | ---------- | ------ |
| 1   | GCP project and APIs            | [01-gcp-project-apis.md](01-gcp-project-apis.md)                           | 30 min | 1          | ✅     |
| 2   | Terraform remote state          | [02-terraform-remote-state.md](02-terraform-remote-state.md)               | 45 min | 1          | ✅     |
| 3   | VPC, subnets, Cloud NAT         | [03-vpc-nat.md](03-vpc-nat.md)                                             | 1 h    | 1          | ✅     |
| 4   | GKE cluster                     | [04-gke-cluster.md](04-gke-cluster.md)                                     | 1–2 h  | 2          | ✅     |
| 5   | Cloud DNS + NS delegation       | [05-cloud-dns.md](05-cloud-dns.md)                                         | 45 min | 2          | ✅     |
| 6   | Static IP + TLS                 | [06-ingress-tls.md](06-ingress-tls.md)                                     | 1 h    | 2          | ✅     |
| 7   | GitHub WIF                      | [07-github-wif.md](07-github-wif.md)                                       | 1 h    | 3          | ✅     |
| 8   | Artifact Registry + Binary Auth | [08-artifact-registry-binary-auth.md](08-artifact-registry-binary-auth.md) | 1 h    | 3          | ✅     |
| 9   | Argo CD bootstrap               | [09-argocd-bootstrap.md](09-argocd-bootstrap.md)                           | 1 h    | 4 **gate** | ✅     |
| 10  | ESO + Secret Manager            | [10-external-secrets.md](10-external-secrets.md)                           | 45 min | 4          | ✅     |
| 11  | Kyverno policies                | [11-kyverno-policies.md](11-kyverno-policies.md)                           | 45 min | 4          | ✅     |
| 12  | Boutique deploy                 | [12-boutique-deploy.md](12-boutique-deploy.md)                             | 1 h    | 5          | ✅     |
| 13  | Observability + SLOs            | [13-observability-slos.md](13-observability-slos.md)                       | 2 h    | 6          | ✅     |
| 14  | PagerDuty                       | [14-pagerduty.md](14-pagerduty.md)                                         | 1 h    | 7          | ✅     |
| 15  | Cloud Armor                     | [15-cloud-armor.md](15-cloud-armor.md)                                     | 45 min | 7          | ✅     |
| 16  | Smoke + SRE verification        | [16-smoke-validation.md](16-smoke-validation.md)                           | 1 h    | 7–8        | ✅     |

Status legend: ⬜ Not started · 🔄 In progress · ✅ Complete

Each guide follows the same SETUP format: Goal, Why, Prerequisites, Commands, Expected output, Validation, Common problems, Recovery, Best practices, Security notes, Next step.

**Phase 4 gate:** Topics 09–11 (Argo CD, ESO, Kyverno) must complete before deploying Boutique (topic 12).

This is the pilot story. Live execution through topic 16 is complete; Phase 8 tore the stack down.

### Dependency graph (pilot path)

```
01 → 02 → 03 → 04 → 05 → 06
                ↓
07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16
```

Topics 7–8 can start after topic 4 (in parallel with 5–6).

### Terraform phases (pilot path)

| Phase | Topics | Terraform modules applied                                                                |
| ----- | ------ | ---------------------------------------------------------------------------------------- |
| 1     | 01–03  | `project_apis`, `time_sleep` (API propagation), `networking` (use `-target` in topic 03) |
| 2     | 04–06  | `gke`, `ingress_edge`, `dns`                                                             |
| 3     | 07–08  | `wif`, `artifact_registry`, `binary_authorization`                                       |
| 4+    | 09–16  | GitOps / Console (Argo CD, ESO, Kyverno, observability, and so on)                       |

### Optional after rebuild — not part of the closed pilot

Guides 17–20 exist in Git as scaffolds only. They were not required for topics 01–16 and are not claimed as demonstrated. Enable them only after a deliberate rebuild; see [ROADMAP](../../ROADMAP.md).

| #   | Topic                                        | Guide                                                                  |
| --- | -------------------------------------------- | ---------------------------------------------------------------------- |
| 17  | Latency SLOs + Grafana dashboards            | [17-latency-slos-dashboards.md](17-latency-slos-dashboards.md)         |
| 18  | SRE operability (HA, Argo uptime, game days) | [18-sre-operability-game-days.md](18-sre-operability-game-days.md)     |
| 19  | Monitoring + Backup Terraform                | [19-monitoring-backup-terraform.md](19-monitoring-backup-terraform.md) |
| 20  | SRE practices (budget, capacity, toil)       | [20-sre-practices-capacity-toil.md](20-sre-practices-capacity-toil.md) |

---

## Related docs

- [Bootstrap summary](../bootstrap.md)
- [DNS reference](../dns.md)
- [Teardown](../teardown.md)
- [Roadmap](../../ROADMAP.md) (maintainer phase detail)

## Collaboration

You run each guide step by step. Confirm completion before moving to the next topic.

After topic 16, see [bootstrap.md](../bootstrap.md) and [teardown.md](../teardown.md).
