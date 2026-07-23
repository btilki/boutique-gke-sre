# Project charter — boutique-gke-sre

## Summary

Production SRE reference for Google Online Boutique on one private regional GKE cluster in GCP project `boutique-gke`, domain `biroltilki.art`.

## Goals

1. Demonstrate production-grade platform engineering on GCP (GitOps, DevSecOps, SRE)
2. Provide operable SLOs, alerting, runbooks, and game-day practice — not slide-ware
3. Serve as a reusable platform baseline and internal engineering reference

→ Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/architecture/overview.md](docs/architecture/overview.md)

## Scope

**In scope:** Single GCP project, one cluster, full SRE + DevSecOps baseline, bootstrap and teardown.

**Out of scope:** Multi-project/cluster, multi-region active-active, service mesh default, custom app code, status page product.

## Production bar

- HTTPS on `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` (when live)
- Kyverno enforced; digest-only images; ESO-only secrets
- SLOs + burn alerts with runbook links; PagerDuty test incident validated
- Latency SLO artifacts + Grafana dashboards in repo (topic 17 — apply on rebuild)
- HA GitOps, Argo uptime, game-day STATUS/TEMPLATE, GD03 postmortem (topic 18 — apply on rebuild)
- Terraform monitoring + GKE Backup modules (topic 19 — enable_*_iac on rebuild)
- Error-budget ritual, capacity baseline, toil cadence (topic 20)
- Game-day scenario executed (2026-07-04); infrastructure decommissioned 2026-07-04

## DNS names (inactive)

Public A records removed with teardown. Names resolve empty until Phase 2 rebuild.

- Storefront: `boutique.biroltilki.art` (**inactive**)
- Argo CD: `argocd.boutique.biroltilki.art` (**inactive**)

See [docs/dns.md](docs/dns.md).

## Related

Phased delivery — one phase per session, validate, commit, proceed.

→ [ROADMAP.md](ROADMAP.md) · [docs/implementation/plan.md](docs/implementation/plan.md) · [docs/setup/README.md](docs/setup/README.md)

## Session rule

**Do not skip Phase 4** (Argo CD + Kyverno + ESO + NetworkPolicy) before treating the cluster as production-ready.

- [README.md](README.md)
- [docs/operations/operations-runbook.md](docs/operations/operations-runbook.md)
