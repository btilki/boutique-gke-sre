# Project charter — boutique-gke-sre

## Summary

Production SRE reference for Google Online Boutique on one private regional GKE cluster in GCP project `boutique-gke`, domain `biroltilki.art`.

## Goals

1. Demonstrate production-grade platform engineering on GCP (GitOps, DevSecOps, SRE)
2. Provide operable SLOs, alerting, runbooks, and game-day practice — not slide-ware
3. Serve as a portfolio artifact and reusable learning reference

→ Hiring review: [PORTFOLIO.md](PORTFOLIO.md)

## Scope

**In scope:** Single GCP project, one cluster, full SRE + DevSecOps baseline, bootstrap and teardown.

**Out of scope:** Multi-project/cluster, multi-region active-active, service mesh default, custom app code, status page product.

## Production bar

- HTTPS on `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art`
- Kyverno enforced; digest-only images; ESO-only secrets
- SLOs + burn alerts with runbook links; PagerDuty test incident validated
- Game-day scenarios documented; teardown validation pending (Phase 8)

## URLs

- Storefront: https://boutique.biroltilki.art
- Argo CD: https://argocd.boutique.biroltilki.art

## Implementation

Phased delivery — one phase per session, validate, commit, proceed.

→ [ROADMAP.md](ROADMAP.md) · [docs/setup/README.md](docs/setup/README.md)

## Session rule

**Do not skip Phase 4** (Argo CD + Kyverno + ESO + NetworkPolicy) before treating the cluster as production-ready.
