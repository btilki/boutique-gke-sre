# Secret Manager module

Secret containers and IAM for External Secrets Operator.

## Purpose

Creates **Secret Manager secret resources** (containers only — values are populated out-of-band or via `gcloud`, never committed to Git). Grants the ESO Workload Identity service account `secretAccessor` on required secrets (e.g. Argo CD admin, PagerDuty integration keys). Supports the ESO-only secrets pattern enforced by Kyverno.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_ |

## Outputs

| Name | Description |
|------|-------------|
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (Secret Manager API enabled)
- `iam` module (ESO Workload Identity SA and bindings)

## Usage

```hcl
module "secret_manager" {
  source = "../../modules/secret-manager"

  project_id = var.project_id

  secrets = {
    argocd-admin-password = {
      labels = { app = "argocd", managed-by = "terraform" }
    }
    pagerduty-integration-key = {
      labels = { app = "monitoring", managed-by = "terraform" }
    }
  }

  accessor_members = [
    module.iam.external_secrets_sa_member,
  ]
}
```

## Implementation phase

**Phase 4** — Argo CD + policies + ESO + NetworkPolicy (**required gate**, [docs/setup/10-external-secrets.md](../../../docs/setup/10-external-secrets.md)).
