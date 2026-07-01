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

## Supply chain

| Control | Tool |
|---------|------|
| Image scan | Trivy (fail critical/high) |
| Sign + attest | cosign |
| Deploy gate | Binary Authorization |
| Admission | Kyverno |

## IAM

Least privilege for CI service accounts and Workload Identity bindings. See [docs/security/iam-matrix.md](docs/security/iam-matrix.md) (Phase 3+).

## Audit

Cloud Audit Logs enabled for admin and data access on sensitive APIs.
