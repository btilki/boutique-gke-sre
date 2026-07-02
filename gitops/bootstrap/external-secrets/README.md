# External Secrets bootstrap

Operator install reference and cluster-wide Secret Manager integration.

## Purpose

Configure External Secrets Operator (ESO) and a `ClusterSecretStore` for GCP Secret Manager. Enforces the ESO-only secret pattern (Kyverno blocks plain `Secret` resources).

## Inputs

| Input             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| Secret Manager    | Secret containers provisioned by Terraform (`secret-manager` module) |
| Workload Identity | ESO controller GSA ↔ KSA binding                                     |
| `operator/`       | Helm install for ESO                                                 |

## Outputs

| Output               | Description                                               |
| -------------------- | --------------------------------------------------------- |
| ESO deployment       | Controller in `external-secrets` namespace                |
| `ClusterSecretStore` | Cluster-wide GCP SM backend (`cluster-secret-store.yaml`) |

## Dependencies

- Phase 4: ESO Helm install (`operator/README.md`)
- Terraform: IAM + Secret Manager secret containers
- Kyverno: `block-plain-secrets` policy in `../../policies/kyverno/`

## Usage

1. Install operator: see `operator/README.md`
2. Uncomment and apply `cluster-secret-store.yaml` after WI is configured
3. Application teams use `ExternalSecret` CRs in app namespaces (Phase 5)
