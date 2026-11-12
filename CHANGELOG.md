# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Closed-pilot landing: root [`README.md`](README.md) (Problem → Decision → Result → Proof → Tradeoffs → Where to start) and [`docs/README.md`](docs/README.md) intent hub.
- Pilot proof pages: [`docs/pilot-claims.md`](docs/pilot-claims.md), [`docs/evidence/README.md`](docs/evidence/README.md), [`docs/lessons-learned.md`](docs/lessons-learned.md).
- CI contract: [`docs/ci.md`](docs/ci.md) (points at [`docs/operations/rollback.md`](docs/operations/rollback.md)).
- Architecture folder nav: [`docs/architecture/README.md`](docs/architecture/README.md).

### Changed

- Closed-pilot path is topics 01–16 plus Phase 8 teardown. Topics 17–20 stay under setup as optional after rebuild only.
- Hubs use production-pilot wording. Outside links stay limited to the sister platforms and Google Online Boutique.

## [0.1.0] — closed pilot

Production pilot through setup topics 01–16 and Phase 8 teardown. GCP resources from that run were destroyed; this repository remains the reference.

### Added

- Terraform foundation: VPC, NAT, private-node GKE, Cloud DNS, ingress TLS, WIF, Artifact Registry, Binary Authorization.
- GitOps: Argo CD (manual sync), ESO + Secret Manager, Kyverno, NetworkPolicy, digest-only Boutique Helm.
- CI: GitHub Actions + WIF → Trivy → AR push → cosign sign + attest → digest PR (**CI never syncs Argo**).
- SRE: browse and checkout availability SLOs, burn-rate alerts, PagerDuty path, runbooks, game days, ordered teardown.
- Setup guides 01–16, ADRs 001–003, operations and security docs.

### Notes

- Hostnames `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` stay offline until a rebuild.
- Optional scaffolds (topics 17–20 / phases 9-A–9-D) are documented for after rebuild; they were not part of the closed pilot path.
