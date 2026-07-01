# ADR 002 — WIF over service account keys

## Status

Accepted

## Context

GitHub Actions needs GCP access for Artifact Registry push and Terraform plan.

## Decision

Use **Workload Identity Federation** with GitHub OIDC. **Prohibit** long-lived GCP service account JSON keys in GitHub Secrets.

## Consequences

- **Positive:** No key rotation burden; short-lived tokens; auditable trust binding
- **Negative:** More initial setup (pool, provider, attribute conditions)
- **Mitigation:** Terraform `wif` module and setup guide 07
