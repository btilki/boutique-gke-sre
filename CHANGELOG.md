# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Closed-reference landing: root [`README.md`](README.md) (Problem → Decision → Result → Proof → Tradeoffs → Where to start) and [`docs/README.md`](docs/README.md) intent hub.
- Reference proof pages: [`docs/reference-claims.md`](docs/reference-claims.md), [`docs/evidence/README.md`](docs/evidence/README.md), [`docs/lessons-learned.md`](docs/lessons-learned.md).
- CI contract: [`docs/ci.md`](docs/ci.md) (points at [`docs/operations/rollback.md`](docs/operations/rollback.md)).
- Architecture folder nav: [`docs/architecture/README.md`](docs/architecture/README.md).

### Changed

- Closed-reference path is topics 01–16 plus Phase 8 teardown. Topics 17–20 stay under setup as optional after rebuild only.
- Hubs use production reference wording. Outside links stay limited to the sister platforms and Google Online Boutique.
- Docs say **reference** instead of **pilot** (`docs/pilot-claims.md` → [`docs/reference-claims.md`](docs/reference-claims.md)).
- Claims, evidence, and lessons pages use engineering voice only (no audience framing).
- Aligned Binary Auth dry-run → Enforce (after topic 16), optional topics 17–20 off the smoke “next” path, NetworkPolicy/CNI honesty, and related overclaims.
- P0 honesty: private-node / public API wording; `enable_argocd_armor` default `false`; latency SLOs labeled optional (topic 17); Phase 8 = teardown (not backup IaC).
- P1 honesty: offline guards on ops/SLO validation; CI mirror (not `docker build`) in topic 08; game-day wording aligned to STATUS; SECURITY advisory URL; dated `0.1.0`.
- P2 polish: short-form abbreviations; `production reference` wording; ownership/timeline on README; ROADMAP 9-B marks GD03 postmortem as lived.
- P3 polish: softer charter/maturity wording; maintainer-only labels; proven / not-shown / deferred table on README.
- P0 (re-audit): Phase 8 = teardown everywhere; WIF scoped to supply-chain workflows; smoke expected table vs edge hardening.
- P1 (re-audit): CI mirror wording; setup 04 public API; NetworkPolicy CNI honesty; short-form abbreviations on setup/security/observability hubs.
- P2 (re-audit): README grammar and game-day caveat; SECURITY/PROJECT polish; evidence and claims wording.
- P3 (re-audit): Soften Decision headlines; refresh `.cursor` project-description (no pilot; private-node + public API).

## [0.1.0] — 2026-07-04

Production reference through setup topics 01–16 and Phase 8 teardown. Date matches the game day 03 report; GCP resources from that run were destroyed afterward. This repository remains the reference.

### Added

- Terraform foundation: VPC, NAT, private-node GKE, Cloud DNS, ingress TLS, WIF, Artifact Registry, Binary Authorization.
- GitOps: Argo CD (manual sync), ESO + Secret Manager, Kyverno, NetworkPolicy, digest-only Boutique Helm.
- CI: GitHub Actions + WIF → Trivy → AR push → cosign sign + attest → digest PR (**CI never syncs Argo**).
- SRE: browse and checkout availability SLOs, burn-rate alerts, PagerDuty path, runbooks, one executed game day (03; PD/alert not verified), ordered teardown.
- Setup guides 01–16, ADRs 001–003, operations and security docs.

### Notes

- Hostnames `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` stay offline until a rebuild.
- Optional scaffolds (topics 17–20 / phases 9-A–9-D) are documented for after rebuild; they were not part of the closed reference path.
