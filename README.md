# boutique-gke-sre

Production SRE reference for [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) on private-node GKE (public API endpoint) — SLOs, burn-rate alerts, PagerDuty, GitOps.

> **Status:** Production reference closed. Phases 1–8 ran end to end; then the GCP resources were destroyed. There is no live GKE cluster or public DNS from that run. To run again, follow [`docs/setup/`](docs/setup/) (topics 01–16).

Author: [Birol Tilki](https://www.linkedin.com/in/birol-tilki-48731326/) — designed, operated, and tore down this reference (topics 01–16; game-day evidence dated 2026-07-04).

**Hostnames (offline until rebuild):** `boutique.biroltilki.art` · `argocd.boutique.biroltilki.art`

---

## Problem

Shipping Online Boutique to a cluster is not the hard part. The hard part is reliability **after deployment**. You need to know when browse or checkout is burning error budget, route that signal to a human with a runbook, and prove the supply chain did not leave `:latest` or unsigned images in the path. A Terraform apply alone does not prove that story.

## Approach

- **One private-node regional GKE cluster** in project `boutique-gke` (public Kubernetes API) — namespaces for isolation, not multi-cluster blast radius ([ADR-001](docs/adr/001-single-cluster.md)).
- **Git is the deploy source of truth** — GitHub Actions mirrors, scans (Trivy), signs (cosign), and opens digest PRs. Operators sync Argo CD by hand ([ADR-003](docs/adr/003-manual-argocd-sync.md)).
- **Admission policy blocks mutable tags and unsigned images** — Kyverno enforces digest-only images, probes, resources, NetworkPolicy labels, and ESO-only secrets. Binary Authorization checks attestations when the cluster admits images.
- **SRE after deployment** — browse and checkout availability SLOs in Cloud Monitoring, multi-window burn alerts, PagerDuty with runbook links, Game day 03 (alert path not verified), and ordered teardown.

## Result

Topics 01–16 completed, then teardown. Documentation and screenshots remain; there are no public A records. Reference claims: [`docs/reference-claims.md`](docs/reference-claims.md).

---

## At a glance

| Field     | Value                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------ |
| What      | SRE-focused private-node GKE (public API) for Online Boutique in `europe-west1`                        |
| Hard rule | Reliability **after deployment** — SLOs → burn alerts → PagerDuty → runbooks                           |
| CI model  | GitHub Actions; WIF on supply-chain jobs; **CI does not sync Argo CD** — digest PRs only               |
| Scope     | Production reference — one project, one cluster; not multi-region HA                                   |
| Stack     | Terraform · GKE · Argo CD · Kyverno · ESO · Binary Authorization · OTel · Cloud Monitoring · PagerDuty |

---

## Proof

These screenshots are from when the stack was live. Full catalog: [`docs/evidence/`](docs/evidence/README.md). Hostnames stay offline until you rebuild.

| Status                        | Examples                                                                                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Proven in screenshots         | Storefront HTTPS, Argo Healthy/Synced, `build-scan-sign`, availability SLOs; more in evidence (Kyverno, Binary Authorization, PagerDuty, Grafana) |
| Documented, no screenshot yet | Digest PR diff, Kyverno deny of `:latest`, Argo OutOfSync → Sync, Binary Authorization deny on `redis-cart`, teardown console                     |
| Deferred                      | Game days 01/02/04; latency SLOs (topic 17); topics 18–20 scaffolds                                                                               |

**Storefront** — `https://boutique.biroltilki.art` over HTTPS (when the reference was live):

![Online Boutique storefront over HTTPS](assets/diagrams/boutique-storefront-https.png)

**Argo CD** — Applications Healthy / Synced:

![Argo CD applications healthy and synced](assets/diagrams/argocd-applications-healthy-synced.png)

**GitHub Actions** — `build-scan-sign` succeeded (Trivy → push → cosign):

![GitHub Actions build-scan-sign success](assets/diagrams/github-actions-build-scan-sign-success.png)

**SLOs** — browse and checkout availability in Cloud Monitoring:

![Browse and checkout SLO dashboard](assets/diagrams/slo-browse-checkout.png)

More: Kyverno, Binary Authorization, PagerDuty test incident, Grafana, Cloud Trace, Cloud Armor — [`docs/evidence/`](docs/evidence/README.md).

---

## Tradeoffs / what I would change for real production

- **Public Kubernetes API endpoint** — nodes are private; the control plane is not. IaC today keeps `enable_private_endpoint = false`. A hardened rebuild would set a private endpoint and master authorized networks ([`SECURITY.md`](SECURITY.md)).
- **Single cluster, one Boutique namespace** — fine for a cost-capped reference; not true env isolation.
- **`redis-cart` attestation gap** — Game day 03 showed Binary Authorization blocking an unsigned restore; PagerDuty ack was not exercised; postmortem actions are still open.
- **Storefront Cloud Armor is a console procedure** — Terraform Armor for Argo CD is off by default (`enable_argocd_armor = false`); enable after topic 16. Storefront WAF was topic 15 by hand.
- **NetworkPolicy may not be enforced by the CNI** — Kyverno requires the label; the GKE module does not pin Dataplane V2 or Calico.

Do **not** call this production-ready. Limits: [`SECURITY.md`](SECURITY.md). Lessons: [`docs/lessons-learned.md`](docs/lessons-learned.md).

---

## Where to start

| I want to…                            | Read                                                                                                                                                                                                                                                                |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Understand the project in ~10 minutes | This page → [`ARCHITECTURE.md`](ARCHITECTURE.md) → [ADR-003](docs/adr/003-manual-argocd-sync.md)                                                                                                                                                                    |
| See reference proof                   | [`docs/reference-claims.md`](docs/reference-claims.md) · [`docs/evidence/`](docs/evidence/README.md)                                                                                                                                                                |
| Review design and SRE                 | [`docs/architecture/overview.md`](docs/architecture/overview.md) · [`docs/sre/`](docs/sre/README.md) · [`docs/ci.md`](docs/ci.md) · [`docs/security/threat-model.md`](docs/security/threat-model.md) · [`docs/operations/rollback.md`](docs/operations/rollback.md) |
| Rebuild or operate                    | [`docs/setup/`](docs/setup/README.md) (topics 01–16) · [`docs/teardown.md`](docs/teardown.md) · [`docs/operations/operations-runbook.md`](docs/operations/operations-runbook.md)                                                                                    |

Full index: [`docs/README.md`](docs/README.md)

---

## Stack flow (summary)

```mermaid
flowchart LR
  GH[GitHub Actions] -->|digest PR only| Git[(Git)]
  GH -->|WIF push sign| AR[Artifact Registry]
  Git -->|pull| Argo[Argo CD]
  Argo --> Boutique[boutique]
  Boutique --> OBS[OTel / Monitoring]
  OBS --> PD[PagerDuty]
  Users((Users)) -->|HTTPS TLS + Armor| Boutique
```

Manual Argo CD sync after merge. Details: [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`docs/architecture/overview.md`](docs/architecture/overview.md).

---

## Repository map

![Boutique GKE SRE — Repository Map and Navigation](assets/boutique-gke-sre-repository-map.png)

```text
boutique-gke-sre/
├── terraform/       # GCP IaC (networking, GKE, WIF, AR, Binary Auth, …)
├── gitops/          # Argo CD apps, Kyverno, NetworkPolicy, Boutique Helm
├── observability/   # OTel, Grafana, SLO / alert YAML
├── docs/            # Setup topics, SRE runbooks, security, architecture
├── scripts/         # Bootstrap checks, game days, teardown helpers
├── tests/           # Policy and manifest validation
└── .github/         # CI workflows (WIF on supply-chain)
```

Full tree: [`REPOSITORY_STRUCTURE.md`](REPOSITORY_STRUCTURE.md)

---

## What the reference demonstrated

- Private-node GKE with HTTPS on the storefront and Argo CD hostnames (when live)
- Digest-only GitOps, Kyverno baseline, ESO + Secret Manager, Binary Authorization
- Browse and checkout availability SLOs, burn-rate alerts, PagerDuty test path
- One executed Game day (03 redis-cart; PagerDuty/alert not verified — see [`docs/sre/game-days/reports/STATUS.md`](docs/sre/game-days/reports/STATUS.md))
- Ordered teardown with orphan-resource scans ([`docs/teardown.md`](docs/teardown.md))

---

## Technology stack

| Area                | Choices                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------ |
| Cloud / region      | GCP `europe-west1`, project `boutique-gke`                                                 |
| IaC                 | Terraform ≥ 1.5                                                                            |
| Kubernetes          | Regional private-node GKE (public API), Workload Identity                                  |
| GitOps / delivery   | Argo CD (manual sync), Helm                                                                |
| Policy / secrets    | Kyverno, ESO, Secret Manager, NetworkPolicy                                                |
| Ingress / TLS       | Google-managed certs, static IP, Cloud Armor                                               |
| CI / supply chain   | GitHub Actions, WIF (supply-chain), Artifact Registry, Trivy, cosign, Binary Authorization |
| Observability / SRE | OTel, Cloud Trace, Managed Prometheus, Grafana, Cloud Monitoring SLOs, PagerDuty           |

---

## Quick clone

```bash
git clone https://github.com/btilki/boutique-gke-sre.git
cd boutique-gke-sre
```

Do not provision GCP from this file. Bootstrap and destroy live under [`docs/setup/`](docs/setup/) and [`docs/teardown.md`](docs/teardown.md). Validate local CLI with `./scripts/bootstrap/validate-prereqs.sh`.

---

## Contributing · License · Related

- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Security: [`SECURITY.md`](SECURITY.md)
- Roadmap: [`ROADMAP.md`](ROADMAP.md)
- License: [`LICENSE`](LICENSE) (Apache 2.0)

| Repository             | Link                                                      |
| ---------------------- | --------------------------------------------------------- |
| Google Online Boutique | https://github.com/GoogleCloudPlatform/microservices-demo |
| boutique-eks-gitops    | https://github.com/btilki/boutique-eks-gitops             |
| boutique-aks-devsecops | https://github.com/btilki/boutique-aks-devsecops          |
