# Documentation index — boutique-gke-sre

Onboarding map for engineers joining the project.

**Guide formats:**

| Type                 | Location          | Sections                                                                                                                                                            |
| -------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setup topics (01–16) | [setup/](setup/)  | **11-section SETUP format** (Goal, Why, Prerequisites, Commands, Expected output, Validation, Common problems, Recovery, Best practices, Security notes, Next step) |
| General docs         | `docs/` elsewhere | **12-section standard** ([Guide template](GUIDE_TEMPLATE.md))                                                                                                       |

## Required artifacts

| Artifact              | Path                                                                   | Status             |
| --------------------- | ---------------------------------------------------------------------- | ------------------ |
| Bootstrap             | [bootstrap.md](bootstrap.md)                                           | Documented         |
| DNS                   | [dns.md](dns.md)                                                       | Documented         |
| Teardown              | [teardown.md](teardown.md)                                             | Documented         |
| Setup index           | [setup/README.md](setup/README.md)                                     | 16 topics complete |
| Architecture          | [architecture/overview.md](architecture/overview.md)                   | 16 sections        |
| SLO catalog           | [sre/slos/catalog.md](sre/slos/catalog.md)                             | Documented         |
| Burn-rate alerting    | [sre/slos/burn-rate-alerting.md](sre/slos/burn-rate-alerting.md)       | Documented         |
| Error budget policy   | [sre/error-budget-policy.md](sre/error-budget-policy.md)               | Documented         |
| Severity              | [sre/incident-response/severity.md](sre/incident-response/severity.md) | Documented         |
| On-call               | [sre/oncall/README.md](sre/oncall/README.md)                           | Documented         |
| Alert testing         | [sre/oncall/test-alerts.md](sre/oncall/test-alerts.md)                 | Documented         |
| Postmortem template   | [sre/postmortems/TEMPLATE.md](sre/postmortems/TEMPLATE.md)             | Documented         |
| Runbooks              | [sre/runbooks/](sre/runbooks/)                                         | Per alert policy   |
| Game days             | [sre/game-days/](sre/game-days/)                                       | 4 scenarios        |
| Supply chain security | [security/supply-chain.md](security/supply-chain.md)                   | Documented         |

**Status key:** _Documented_ = artifact exists in Git. _Implemented in GCP_ = applied in live environment (varies by phase).

## Documentation sets

```
docs/
├── architecture/     # System design, ADRs
├── setup/            # Topic guides 01–16 (user-executed)
├── sre/              # Runbooks, SLOs, on-call, game days
├── security/         # Threat model, IAM, supply chain
├── operations/       # Day-2 ops, rollback
├── troubleshooting/  # Cross-cutting fixes
└── implementation/   # Phased roadmap
```

## Standard validation (live system)

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
- [ ] Terraform Phase 3+ modules implemented (WIF, AR, Binary Auth)
- [x] Helm chart templates + digest pins for Boutique deploy (Phase 5 / topic 12)
- [x] OTel collector manifests + observability Kustomize bundle (Phase 6 / topic 13)
- [ ] Alert policies in GCP link to runbook URLs (verify in Console — topic 13–14)
