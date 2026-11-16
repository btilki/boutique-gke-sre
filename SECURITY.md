# Security

## Reporting vulnerabilities

Closed reference — see [docs/reference-claims.md](docs/reference-claims.md). Report vulnerabilities in the docs, IaC, workflows, or manifests responsibly.

**Contact:** Open a private [GitHub Security Advisory](https://github.com/btilki/boutique-gke-sre/security/advisories) for this repository. Do not open a public issue for exploitable vulnerabilities.

## Design principles

Closed-run posture; gaps are listed under Current limits.

- **No long-lived GCP keys in GitHub** — WIF on supply-chain workflows; no JSON keys
- **No secrets in Git** — gitleaks in pre-commit; Secret Manager via ESO
- **Digest-only images** — Kyverno rejects mutable tags
- **Signed artifacts** — cosign + Binary Authorization (cluster rule; Enforce after smoke)
- **Network default-deny** — NetworkPolicy manifests with explicit allows (CNI pin required — see limits)
- **Edge protection** — Cloud Armor on storefront ingress (console path in the closed reference)

## Current limits

Principles above guide design; the gaps below override any “already enforced” reading for the closed run.

- The Kubernetes API endpoint is public (`enable_private_endpoint = false` in `terraform/modules/gke`). Master authorized networks are not set. Node OAuth scope is `https://www.googleapis.com/auth/cloud-platform`.
- Binary Authorization's project default is allow plus dry-run. Only this cluster's admission rule requires an attestation.
- `redis-cart` was not attested during Game day 03 (`redis-cart`). The action items in [docs/sre/postmortems/2026-07-04-redis-cart-down.md](docs/sre/postmortems/2026-07-04-redis-cart-down.md) are still open. Signing uses a long-lived cosign private key in GitHub secrets.
- Storefront Cloud Armor is a console procedure in [docs/setup/15-cloud-armor.md](docs/setup/15-cloud-armor.md). The Terraform Argo CD Armor policy defaults to off (`enable_argocd_armor = false`); set `true` after topic 16. The rules are SQLi, XSS, and a rate limit, then default allow.
- The GKE module does not set Dataplane V2 or the Calico network-policy addon. NetworkPolicy objects in Git are not pinned to an enforcing dataplane. Kyverno checks the namespace label. It does not prove the CNI is dropping packets.

## Supply chain

| Control       | Tool                       |
| ------------- | -------------------------- |
| Image scan    | Trivy (fail critical/high) |
| Sign + attest | cosign                     |
| Deploy gate   | Binary Authorization       |
| Admission     | Kyverno                    |

## IAM

Least privilege for CI service accounts and Workload Identity bindings. See [docs/security/iam-matrix.md](docs/security/iam-matrix.md) (Phase 3+).

## Audit

Cloud Audit Logs enabled for admin and data access on sensitive APIs.
