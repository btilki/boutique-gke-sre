# Project charter — boutique-gke-sre

## Summary

Production-pilot SRE reference for [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) on one private regional GKE cluster in GCP project `boutique-gke`, domain `biroltilki.art`.

## Goals

1. Run a production-pilot platform on GCP (GitOps, DevSecOps, SRE)
2. Provide operable SLOs, alerting, runbooks, and game-day practice — not slides only
3. Serve as a reusable platform baseline and internal engineering reference

→ Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/architecture/overview.md](docs/architecture/overview.md)

## Scope

**In scope:** Single GCP project, one cluster, full SRE + DevSecOps baseline, bootstrap and teardown.

**Out of scope:** Multi-project/cluster, multi-region active-active, service mesh default, custom app code, status page product.

## Pilot checklist

- HTTPS on `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` (when live)
- Kyverno enforced; digest-only images; ESO-only secrets
- SLOs + burn alerts with runbook links; PagerDuty test incident validated
- Game-day scenario executed; infrastructure decommissioned

Optional guides after a deliberate rebuild live under [`docs/setup/README.md`](docs/setup/README.md). They are not part of this checklist.

## DNS names (offline)

Public A records were removed with teardown. Names stay empty until a Phase 2 rebuild.

- Storefront: `boutique.biroltilki.art` (offline)
- Argo CD: `argocd.boutique.biroltilki.art` (offline)

See [docs/dns.md](docs/dns.md).

## Related

Phased delivery — one phase per session, validate, commit, proceed.

→ [ROADMAP.md](ROADMAP.md) · [docs/implementation/plan.md](docs/implementation/plan.md) · [docs/setup/README.md](docs/setup/README.md)

## Session rule

**Do not skip Phase 4** (Argo CD + Kyverno + ESO + NetworkPolicy) before deploying Boutique.

- [README.md](README.md)
- [docs/operations/operations-runbook.md](docs/operations/operations-runbook.md)
