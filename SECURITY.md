# Security

## Reporting vulnerabilities

If you discover a security issue, please report it responsibly. Do not open public issues for exploitable vulnerabilities.

**Contact:** Open a private security advisory on GitHub or contact the repository maintainer directly.

## Design principles

- **No long-lived GCP keys in GitHub** — Workload Identity Federation only
- **No secrets in Git** — gitleaks in pre-commit; Secret Manager via ESO
- **Digest-only images** — Kyverno rejects mutable tags
- **Signed artifacts** — cosign + Binary Authorization at deploy
- **Network default-deny** — NetworkPolicy with explicit allows
- **Edge protection** — Cloud Armor on storefront ingress

## Current limits

The principles above are the target. This repository still has these gaps. Do not describe them as already enforced.

- The Kubernetes API endpoint is public (`enable_private_endpoint = false` in `terraform/modules/gke`). Master authorized networks are not set. Node OAuth scope is `https://www.googleapis.com/auth/cloud-platform`.
- Binary Authorization's project default is allow plus dry-run. Only this cluster's admission rule requires an attestation.
- `redis-cart` was not attested during the Redis cart game day. The action items in [docs/sre/postmortems/2026-07-04-redis-cart-down.md](docs/sre/postmortems/2026-07-04-redis-cart-down.md) are still open. Signing uses a long-lived cosign private key in GitHub secrets.
- Storefront Cloud Armor is a console procedure in [docs/setup/15-cloud-armor.md](docs/setup/15-cloud-armor.md). The Terraform module covers the Argo CD policy and stays off unless `enable_argocd_armor` is set. The rules are SQLi, XSS, and a rate limit, then default allow.
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
