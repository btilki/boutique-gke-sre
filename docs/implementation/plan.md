# Implementation plan — boutique-gke-sre

**Audience:** Implementer during build and rebuild
**Public summary:** [ROADMAP.md](../../ROADMAP.md)
**Architecture (authoritative):** [docs/architecture/overview.md](../architecture/overview.md) · [ARCHITECTURE.md](../../ARCHITECTURE.md)
**Setup guides:** [docs/setup/README.md](../setup/README.md)

**Plan version:** 2026-07-25
**Status:** Phases **1–8** lived and torn down (2026-07-04). Phases **9-A–9-D** repo-ready (apply topics 17–20 on rebuild).

---

## 1. Executive summary

| Field              | Value                                                                                                                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project            | **boutique-gke-sre**                                                                                                                                                                     |
| Goal               | Production **SRE** (**Site Reliability Engineering**) reference for Online Boutique on one private **GKE** (**Google Kubernetes Engine**) cluster in **GCP** (**Google Cloud Platform**) |
| Domain             | `biroltilki.art` — hostnames currently **inactive** ([dns.md](../dns.md))                                                                                                                |
| Phases             | **1–8** (bootstrap → teardown) + **9-A–9-D** (SRE expansion)                                                                                                                             |
| Overall complexity | **L** (platform breadth); Phase 4 is the production gate                                                                                                                                 |
| Current mode       | Repo retained as reference; live apply deferred until rebuild                                                                                                                            |
| Definition of done | Production bar in [PROJECT.md](../../PROJECT.md); topics 01–16 validated historically; 17–20 artifacts in Git                                                                            |

---

## 2. Project goals

| ID   | Goal                          | Success indicator                                             |
| ---- | ----------------------------- | ------------------------------------------------------------- |
| G-01 | Reproducible GCP foundation   | Terraform remote state; VPC; private GKE; DNS + TLS           |
| G-02 | GitOps-only app delivery      | Argo CD manual sync; digest-pinned Boutique                   |
| G-03 | Supply-chain baseline         | WIF CI, Trivy, cosign, Binary Authorization, Kyverno          |
| G-04 | Secrets without Git plaintext | ESO + Secret Manager only                                     |
| G-05 | Operable SLOs                 | Availability + latency SLOs; burn alerts; runbooks; PagerDuty |
| G-06 | On-call readiness             | SEV taxonomy; game days; postmortems                          |
| G-07 | Safe lifecycle                | Bootstrap + teardown + backup/restore documented              |
| G-08 | SRE expansion (9-A–9-D)       | Topics 17–20 repo-ready; apply on rebuild                     |

---

## 3. Business value

- Production-quality GCP platform reference (not a throwaway demo)
- Educational setup topics with rationale (why private GKE, WIF, burn rates)
- Operable reliability: SLOs, error budgets, runbooks, one executed game day
- Cost-conscious teardown path with orphan-scan hygiene

---

## 4. Functional requirements

| ID    | Requirement                                             | Phase / topic |
| ----- | ------------------------------------------------------- | ------------- |
| FR-01 | Terraform: APIs, VPC/NAT, remote state                  | 1 / 01–03     |
| FR-02 | Private GKE, static IP, Cloud DNS, managed TLS          | 2 / 04–06     |
| FR-03 | GitHub WIF, Artifact Registry, Binary Authorization, CI | 3 / 07–08     |
| FR-04 | Argo CD, ESO, Kyverno, NetworkPolicy (**gate**)         | 4 / 09–11     |
| FR-05 | Online Boutique Helm GitOps (digest-only)               | 5 / 12        |
| FR-06 | OTel, Grafana, Cloud Monitoring SLOs + burn alerts      | 6 / 13        |
| FR-07 | PagerDuty, Armor, smoke validation                      | 7 / 14–16     |
| FR-08 | Teardown + backup/restore runbooks                      | 8 / teardown  |
| FR-09 | Latency SLOs + Grafana dashboards                       | 9-A / 17      |
| FR-10 | HA GitOps, Argo uptime, game-day ops                    | 9-B / 18      |
| FR-11 | Monitoring + GKE Backup Terraform modules               | 9-C / 19      |
| FR-12 | Error-budget ritual, capacity, toil cadence             | 9-D / 20      |

---

## 5. Non-functional requirements

| Area                      | Target                                     |
| ------------------------- | ------------------------------------------ |
| Browse availability SLO   | 99.9% (30-day)                             |
| Checkout availability SLO | 99.95% (30-day)                            |
| Browse latency SLO        | p95 &lt; 500ms                             |
| Checkout latency SLO      | p95 &lt; 1000ms                            |
| Images                    | Digest-only; no `:latest`                  |
| Artifacts                 | cosign sign + attest; Binary Authorization |
| Policy                    | Kyverno + NetworkPolicy; ESO-only secrets  |
| Incidents                 | SEV1–SEV4; blameless postmortems           |

See [architecture/overview.md](../architecture/overview.md) §1.

---

## 6. Assumptions

| Assumption                                         | Validate     |
| -------------------------------------------------- | ------------ |
| GCP project `boutique-gke` with billing            | Topic 01     |
| Domain `biroltilki.art` delegatable to Cloud DNS   | Topic 05     |
| GitHub Actions + WIF possible                      | Topics 07–08 |
| PagerDuty available for routing tests              | Topic 14     |
| User executes cloud/CLI; AI authors repo artifacts | All topics   |
| Topics 17–20 apply after rebuild of 01–16          | Topics 17–20 |

---

## 7. Constraints

| Constraint                                   | Impact           |
| -------------------------------------------- | ---------------- |
| One GCP project, one regional private GKE    | No multi-cluster |
| WIF for CI — no long-lived SA keys in GitHub | Topics 07–08     |
| Manual Argo CD sync (prod-style)             | ADR-003          |
| Private nodes; egress via Cloud NAT          | Topic 04         |
| No service mesh / multi-region as default    | Non-goals        |

---

## 8. Scope

### In scope

- Terraform modules + `environments/boutique`
- GitOps (Argo CD, Boutique Helm, Kyverno, NetworkPolicy, ESO)
- Observability (OTel, Grafana, Cloud Monitoring SLOs/alerts)
- SRE docs (runbooks, game days, on-call, error budget)
- Setup topics 01–20; teardown; backup modules

### Out of scope

- Multiple projects or clusters
- Multi-region active-active
- Service mesh as default
- FinOps-first optimization
- Custom Boutique application code
- Built-in status page product
- Optional later: C2 (SLO burn in Terraform), Chaos Mesh, Slack budget bot

---

## 9. Risks

| Risk                                    | Likelihood | Impact | Mitigation                                        |
| --------------------------------------- | ---------- | ------ | ------------------------------------------------- |
| Cost from always-on cluster             | Medium     | Medium | Teardown guide; autoscaling; orphan scan          |
| Binary Auth blocks valid deploys        | Medium     | High   | Attestor docs; test before Phase 5                |
| Kyverno blocks Boutique                 | Medium     | High   | Policy tests in CI; Helm values                   |
| Alert fatigue                           | Medium     | Medium | Multi-window burn rates; SEV routing              |
| Terraform drift / state lock            | Low        | High   | GCS backend; `terraform plan` in CI               |
| Docs imply live URLs while DNS inactive | Medium     | Low    | Inactive DNS wording; no clickable https in prose |

---

## 10. Dependencies

**External:** GCP billing, DNS registrar, GitHub, PagerDuty
**Internal:** Phase order 1 → 2 → 3 → **4 (gate)** → 5 → 6 → 7 → 8; then 9-A–9-D on rebuild

---

## 11. Technology stack

| Layer      | Technologies                                                                                                                                          |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| GCP        | GKE, Cloud DNS, Monitoring, Logging, Managed Prometheus, Trace, Artifact Registry, WIF, Secret Manager, Binary Authorization, Cloud Armor, GKE Backup |
| Kubernetes | Argo CD, Helm, Kyverno, ESO, NetworkPolicy, Prometheus, Grafana, OTel, HPA, PDB                                                                       |
| Platform   | Terraform, GitHub Actions, Trivy, cosign, PagerDuty, pre-commit, gitleaks                                                                             |

---

## 12. Architecture

```
Git (GitHub)
 → GitHub Actions (WIF → GCP; Trivy, cosign, PR gates)
 → Artifact Registry (digest + attestation, Binary Authorization)
 → Argo CD
 → ONE GKE cluster (Helm, Kyverno, ESO, NetworkPolicy)
 → HTTPS (Cloud Armor, Google-managed TLS, static IP)
 → OTel → Cloud Trace / Managed Prometheus / Grafana
 → PagerDuty
```

Canonical detail: [architecture/overview.md](../architecture/overview.md).

---

## 13. Repository organization

```
boutique-gke-sre/
├── terraform/          # GCP IaC
├── gitops/             # Argo CD apps + policies
├── observability/      # OTel, Grafana, Cloud Monitoring defs
├── docs/
│   ├── setup/          # Topics 01–20
│   ├── implementation/ # This plan
│   └── sre/            # Runbooks, SLOs, game days
├── scripts/            # Validation, game days, teardown, load
└── .github/            # CI workflows
```

See [REPOSITORY_STRUCTURE.md](../../REPOSITORY_STRUCTURE.md).

---

## 14. Milestones

| Milestone        | Phases  | Outcome                              |
| ---------------- | ------- | ------------------------------------ |
| M1 Foundation    | 1–2     | VPC, GKE, DNS, TLS                   |
| M2 Supply chain  | 3       | WIF, AR, Binary Auth, CI             |
| M3 Platform gate | 4       | Argo CD, ESO, Kyverno, NetworkPolicy |
| M4 App live      | 5       | Boutique HTTPS                       |
| M5 Observability | 6–7     | SLOs, PagerDuty, smoke               |
| M6 Lifecycle     | 8       | Teardown + backup docs               |
| M7 SRE expansion | 9-A–9-D | Topics 17–20 repo-ready              |

---

## 15. Phase status

| Phase   | Focus                                    | Size | Status        | Setup                                            |
| ------- | ---------------------------------------- | ---- | ------------- | ------------------------------------------------ |
| **1**   | Repo + Terraform foundation              | S    | ✅ Complete   | 01–03                                            |
| **2**   | GKE + DNS + ingress + TLS                | L    | ✅ Complete   | 04–06                                            |
| **3**   | WIF + Artifact Registry + CI             | M    | ✅ Complete   | 07–08                                            |
| **4**   | Argo CD + policies + ESO + NP (**gate**) | L    | ✅ Complete   | 09–11                                            |
| **5**   | Online Boutique deploy                   | M    | ✅ Complete   | 12                                               |
| **6**   | Observability + SLOs                     | L    | ✅ Complete   | 13                                               |
| **7**   | SRE ops + smoke                          | M    | ✅ Complete   | 14–16                                            |
| **8**   | Teardown + backup/restore                | M    | ✅ Complete   | [teardown](../teardown.md)                       |
| **9-A** | Latency SLOs + Grafana                   | M    | ✅ Repo ready | [17](../setup/17-latency-slos-dashboards.md)     |
| **9-B** | HA, Argo uptime, game days               | M    | ✅ Repo ready | [18](../setup/18-sre-operability-game-days.md)   |
| **9-C** | Monitoring + Backup Terraform            | M    | ✅ Repo ready | [19](../setup/19-monitoring-backup-terraform.md) |
| **9-D** | Error budget, capacity, toil             | M    | ✅ Repo ready | [20](../setup/20-sre-practices-capacity-toil.md) |

### Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
                              └──────────→ 9-A (topic 17)
                              └──────────→ 9-B (topic 18)
                              └──────────→ 9-C (topic 19)
                              └──────────→ 9-D (topic 20)
```

---

## 16. Validation (rebuild checklist)

After rebuild through topic 16:

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
make validate
make runbook-lint
```

Then apply topics **17–20** per their guides. DNS must be **active** again before HTTPS checks pass.

---

## 17. Collaboration

- AI: architecture, manifests, Terraform, docs, guides
- User: executes setup topics, `terraform apply`, `kubectl`, Argo sync, commits
- Do not replace documented setup steps with install-only scripts unless requested

---

## 18. Further reading

- [ROADMAP.md](../../ROADMAP.md) — short status table
- [PROJECT.md](../../PROJECT.md) — charter and production bar
- [bootstrap.md](../bootstrap.md) — executive bootstrap path
- [setup/README.md](../setup/README.md) — topic index
- [DOCUMENTATION.md](../DOCUMENTATION.md) — doc standards and terminology
