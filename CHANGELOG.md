# Changelog

Notable changes to this project. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Root [`README.md`](README.md) closed-reference landing and [`docs/README.md`](docs/README.md) documentation index.
- Proof pages: [`docs/reference-claims.md`](docs/reference-claims.md), [`docs/evidence/README.md`](docs/evidence/README.md), [`docs/lessons-learned.md`](docs/lessons-learned.md).
- CI contract: [`docs/ci.md`](docs/ci.md) (links [`docs/operations/rollback.md`](docs/operations/rollback.md)).
- Architecture folder nav: [`docs/architecture/README.md`](docs/architecture/README.md).

### Changed

- Closed-reference path is topics 01–16 plus Phase 8 teardown. Topics 17–20 are optional after rebuild only.
- Prefer **production reference** wording; outside links limited to sister platforms and Google Online Boutique.
- Docs match the closed run: private-node / public API; Armor default off; Phase 8 = teardown; WIF on supply-chain only; CI mirrors images; Game day 03 only (04 deferred); smoke expected table vs edge hardening.

## [0.1.0] — 2026-07-04

Production reference through setup topics 01–16 and Phase 8 teardown. Date matches the Game day 03 report; GCP resources from that run were destroyed afterward. This repository remains the reference.

### Added

- Terraform foundation: VPC, NAT, private-node GKE, Cloud DNS, ingress TLS, WIF, Artifact Registry, Binary Authorization.
- GitOps: Argo CD (manual sync), ESO + Secret Manager, Kyverno, NetworkPolicy, digest-only Boutique Helm.
- Observability and SRE: OTel, Cloud Monitoring availability SLOs, burn alerts, PagerDuty, runbooks, Game day 03 report.
- CI: mirror → Trivy → cosign → digest PR; PR gates without GCP.

### Changed

- Docs say **reference** instead of **pilot** (`docs/pilot-claims.md` → [`docs/reference-claims.md`](docs/reference-claims.md)).
