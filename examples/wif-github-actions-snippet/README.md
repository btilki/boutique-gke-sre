# GitHub Actions WIF snippet

Workload Identity Federation pattern for CI → GCP without long-lived keys.

## Purpose

Reference workflow fragment for authenticating to GCP from GitHub Actions using WIF. Production workflow: [.github/workflows/build-scan-sign.yml](../../.github/workflows/build-scan-sign.yml).

## Files

| File | Purpose |
|------|---------|
| `wif-auth.yml.example` | Minimal `permissions` + `google-github-actions/auth` step |

## Prerequisites

- WIF pool and provider ([docs/setup/07-github-wif.md](../../docs/setup/07-github-wif.md))
- GitHub repository configured with `GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT` secrets

## Security

- Use `id-token: write` permission only on jobs that need WIF
- Bind CI SA with least privilege (Artifact Registry writer, not owner)
- No JSON key files in secrets

## Further reading

- [examples/README.md](../README.md)
- [docs/adr/002-wif-over-sa-keys.md](../../docs/adr/002-wif-over-sa-keys.md)
