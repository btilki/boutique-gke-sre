# Documentation index — boutique-gke-sre

Onboarding map for engineers joining the project.

**Guide formats:**

| Type                 | Location          | Sections                                                                                                                                                            |
| -------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setup topics (01–20) | [setup/](setup/)  | **11-section SETUP format** (Goal, Why, Prerequisites, Commands, Expected output, Validation, Common problems, Recovery, Best practices, Security notes, Next step) |
| General docs         | `docs/` elsewhere | **12-section standard** ([Guide template](GUIDE_TEMPLATE.md))                                                                                                       |

**Terminology:** On first mention in the home doc for a term, write **abbreviation** (**full form**), both bold — e.g. **SLO** (**Service Level Objective**). See [GUIDE_TEMPLATE.md](GUIDE_TEMPLATE.md).

| Abbreviation | Full form                         | Home document                                                          |
| ------------ | --------------------------------- | ---------------------------------------------------------------------- |
| **GCP**      | **Google Cloud Platform**         | [architecture/overview.md](architecture/overview.md)                   |
| **GKE**      | **Google Kubernetes Engine**      | [architecture/overview.md](architecture/overview.md)                   |
| **SRE**      | **Site Reliability Engineering**  | [sre/README.md](sre/README.md)                                         |
| **SLO**      | **Service Level Objective**       | [sre/slos/catalog.md](sre/slos/catalog.md)                             |
| **SLI**      | **Service Level Indicator**       | [sre/slos/catalog.md](sre/slos/catalog.md)                             |
| **SEV**      | **severity**                      | [sre/incident-response/severity.md](sre/incident-response/severity.md) |
| **DNS**      | **Domain Name System**            | [dns.md](dns.md)                                                       |
| **IaC**      | **Infrastructure as Code**        | [../terraform/README.md](../terraform/README.md)                       |
| **WIF**      | **Workload Identity Federation**  | [security/supply-chain.md](security/supply-chain.md)                   |
| **ESO**      | **External Secrets Operator**     | [security/supply-chain.md](security/supply-chain.md)                   |
| **AR**       | **Artifact Registry**             | [security/supply-chain.md](security/supply-chain.md)                   |
| **BA**       | **Binary Authorization**          | [security/supply-chain.md](security/supply-chain.md)                   |
| **OTel**     | **OpenTelemetry**                 | [../observability/README.md](../observability/README.md)               |
| **GMP**      | **Google Managed Prometheus**     | [../observability/README.md](../observability/README.md)               |
| **HPA**      | **Horizontal Pod Autoscaler**     | [sre/capacity/baseline.md](sre/capacity/baseline.md)                   |
| **PDB**      | **Pod Disruption Budget**         | [sre/capacity/baseline.md](sre/capacity/baseline.md)                   |
| **HA**       | **high availability**             | [sre/capacity/baseline.md](sre/capacity/baseline.md)                   |
| **TLS**      | **Transport Layer Security**      | [setup/06-ingress-tls.md](setup/06-ingress-tls.md)                     |
| **GitOps**   | **Git-based continuous delivery** | [../gitops/README.md](../gitops/README.md)                             |

## Required artifacts

| Artifact              | Path                                                                   | Status                                            |
| --------------------- | ---------------------------------------------------------------------- | ------------------------------------------------- |
| Bootstrap             | [bootstrap.md](bootstrap.md)                                           | Documented                                        |
| Implementation plan   | [implementation/plan.md](implementation/plan.md)                       | Documented                                        |
| DNS                   | [dns.md](dns.md)                                                       | Documented                                        |
| Teardown              | [teardown.md](teardown.md)                                             | Documented                                        |
| Setup index           | [setup/README.md](setup/README.md)                                     | 20 topics (01–16 bootstrap; 17–20 Phases 9-A–9-D) |
| Architecture          | [architecture/overview.md](architecture/overview.md)                   | 16 sections                                       |
| SLO catalog           | [sre/slos/catalog.md](sre/slos/catalog.md)                             | Documented                                        |
| Burn-rate alerting    | [sre/slos/burn-rate-alerting.md](sre/slos/burn-rate-alerting.md)       | Documented                                        |
| Error budget policy   | [sre/error-budget-policy.md](sre/error-budget-policy.md)               | Documented                                        |
| Severity              | [sre/incident-response/severity.md](sre/incident-response/severity.md) | Documented                                        |
| On-call               | [sre/oncall/README.md](sre/oncall/README.md)                           | Documented                                        |
| Alert testing         | [sre/oncall/test-alerts.md](sre/oncall/test-alerts.md)                 | Documented                                        |
| Postmortem template   | [sre/postmortems/TEMPLATE.md](sre/postmortems/TEMPLATE.md)             | Documented                                        |
| Runbooks              | [sre/runbooks/](sre/runbooks/)                                         | Per alert policy                                  |
| Game days             | [sre/game-days/](sre/game-days/)                                       | 4 scenarios                                       |
| Supply chain security | [security/supply-chain.md](security/supply-chain.md)                   | Documented                                        |

**Status key:** _Documented_ = artifact exists in Git. _Implemented in GCP_ = applied in live environment (varies by phase).

## Documentation sets

```
docs/
├── architecture/     # System design, ADRs
├── implementation/   # Implementation plan (plan.md)
├── setup/            # Topic guides 01–20 (user-executed; 17–20 = SRE expansion)
├── sre/              # Runbooks, SLOs, on-call, game days
├── security/         # Threat model, IAM, supply chain
├── operations/       # Day-2 ops, rollback
├── troubleshooting/  # Cross-cutting fixes
```

Phase status: [ROADMAP.md](../ROADMAP.md) at repository root.

## Standard validation (when live)

Public DNS is **inactive** after teardown (`dig +short` empty). After rebuild:

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

## Collaboration

You execute setup steps in [setup/](setup/). Guides are the source of truth — not install scripts.

## Deliverable checklist

- [x] Core SRE artifacts present
- [x] Runbook naming matches alert policies
- [x] Error budget + severity linked
- [x] All setup guides 01–16 written (SETUP format)
- [x] Setup topics 17–20 (Phases 9-A–9-D) written
- [x] Terraform Phase 3 modules (WIF, AR, Binary Auth) in repo
- [x] Helm chart templates + digest pins for Boutique deploy (Phase 5 / topic 12)
- [x] OTel collector manifests + observability Kustomize bundle (Phase 6 / topic 13)
- [ ] Alert policies in GCP link to runbook URLs (verify in Console after rebuild — topics 13–14, 17–18)
- [x] Public DNS documented as inactive until rebuild ([dns.md](dns.md))
