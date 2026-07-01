# External Secrets Operator install

Helm install reference for the External Secrets Operator (ESO).

## Purpose

Install ESO so application secrets are sourced from GCP Secret Manager via `ExternalSecret` CRs — no plain `Secret` manifests in Git.

## Inputs

| Input | Description |
|-------|-------------|
| GKE cluster | Private regional cluster |
| Workload Identity | GSA bound to ESO controller SA (Terraform `iam` module) |
| Helm chart | `external-secrets/external-secrets` (version pinned in Phase 4) |

## Outputs

| Output | Description |
|--------|-------------|
| ESO controller | Watches `ExternalSecret` / `ClusterSecretStore` CRs |
| CRDs | `ExternalSecret`, `SecretStore`, `ClusterSecretStore`, etc. |

## Dependencies

- Phase 4 setup: `10-external-secrets.md` in setup guide
- `../cluster-secret-store.yaml` applied after operator is healthy

## Usage

```bash
# Phase 4 — after Workload Identity for ESO is configured
helm repo add external-secrets https://charts.external-secrets.io
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  -f values.yaml
```

Then apply `../cluster-secret-store.yaml`.
