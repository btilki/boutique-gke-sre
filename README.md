# boutique-gke-sre

> **Infrastructure:** Decommissioned. Documentation and screenshots remain; public DNS names are **inactive** (no A records until rebuild).

Production-pilot **platform + SRE** stack for [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) on a single regional GKE cluster in GCP (`boutique-gke`), with private nodes and a public API endpoint.

Author: [Birol Tilki](https://www.linkedin.com/in/birol-tilki-48731326/)

**DNS names (inactive):** `boutique.biroltilki.art` · `argocd.boutique.biroltilki.art`

### At a glance (30 seconds)

|                   |                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| **What**          | SRE-focused private GKE platform for Online Boutique — SLOs, burn-rate alerts, runbooks                      |
| **Lens**          | Reliability after deploy: observability → PagerDuty → incident paths                                         |
| **Also included** | GitOps, supply-chain controls, private-node baseline (public API endpoint)                                   |
| **State**         | Phases 1–8 lived; infra **torn down**; Phase 9 SRE expansion ready to apply on rebuild                       |
| **Start reading** | [ARCHITECTURE.md](ARCHITECTURE.md) → [docs/setup/README.md](docs/setup/README.md) → observability / SLO docs |

---

## Start here

| Audience                             | Document                                                                                            |
| ------------------------------------ | --------------------------------------------------------------------------------------------------- |
| **Operators and platform engineers** | [docs/setup/README.md](docs/setup/README.md) — topic guides 01–20                                   |
| **Architecture and design**          | [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/architecture/overview.md](docs/architecture/overview.md) |
| **Day-2 operations**                 | [docs/operations/operations-runbook.md](docs/operations/operations-runbook.md)                      |
| **Teardown and lifecycle**           | [docs/teardown.md](docs/teardown.md)                                                                |

---

## What this is

A production-pilot GCP platform for [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo). One regional private GKE cluster with GitOps, supply-chain controls, observability, SLOs, burn-rate alerting, PagerDuty routing, and runbooks.

```mermaid
flowchart LR
  GH[GitHub] --> GKE[Private GKE]
  GKE --> OBS[Observability]
  OBS --> PD[PagerDuty]
```

→ Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/architecture/overview.md](docs/architecture/overview.md)

---

## Operational focus

This repository is the production-pilot reference for site reliability of Online Boutique
on Google Cloud: SLOs, alerting, incident response, error budgets, and runbooks.
GitOps and security controls are implemented on a single private GKE cluster.

**DNS names (inactive until rebuild):** `boutique.biroltilki.art` · `argocd.boutique.biroltilki.art`

---

## Repository layout

| Path             | Purpose                              |
| ---------------- | ------------------------------------ |
| `terraform/`     | GCP infrastructure                   |
| `gitops/`        | Argo CD apps, Kyverno, NetworkPolicy |
| `observability/` | OTel, Grafana, SLOs and alerts       |
| `docs/`          | Setup guides, SRE runbooks, security |
| `.github/`       | CI/CD workflows and templates        |

→ Full layout: [REPOSITORY_STRUCTURE.md](REPOSITORY_STRUCTURE.md)

## Tools

Local CLI used by setup guides (topic 01 onward). Validate with `./scripts/bootstrap/validate-prereqs.sh`.

| Tool        | Notes                                    |
| ----------- | ---------------------------------------- |
| `gcloud`    | Google Cloud SDK; project `boutique-gke` |
| `terraform` | ≥ 1.5                                    |
| `kubectl`   | Cluster access after topic 04            |
| `helm`      | v3+ (Argo CD install, topic 09)          |
| `dig`       | DNS checks (topics 05–06, 16)            |
| `curl`      | HTTPS smoke checks                       |

Also useful later: `argocd` CLI, `cosign`, `trivy`, `pre-commit`, `gitleaks`.

---

## Status

| Phase | Focus                               | Status                           |
| ----- | ----------------------------------- | -------------------------------- |
| 1–7   | Bootstrap through smoke validation  | ✅ Complete                      |
| 8     | Teardown + backup/restore           | ✅ Complete                      |
| 9-A–D | SRE expansion (repo + setup guides) | ✅ Repo ready (apply on rebuild) |

→ [ROADMAP.md](ROADMAP.md) · [PROJECT.md](PROJECT.md)

---

## Contributing & license

→ [CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](SECURITY.md) · [LICENSE](LICENSE) (Apache 2.0)

**CI/CD & workflows:** [.github/workflows/README.md](.github/workflows/README.md)

## Related

| Repository             | Link                                                      |
| ---------------------- | --------------------------------------------------------- |
| Google Online Boutique | https://github.com/GoogleCloudPlatform/microservices-demo |
| boutique-eks-gitops    | https://github.com/btilki/boutique-eks-gitops             |
| boutique-aks-devsecops | https://github.com/btilki/boutique-aks-devsecops          |
