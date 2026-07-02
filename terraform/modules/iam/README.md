# IAM module

Workload Identity service accounts and project-level IAM bindings.

## Purpose

Creates **Google service accounts** and **IAM bindings** for Kubernetes Workload Identity: External Secrets Operator (Secret Manager read), observability exporters, backup agents, and other platform components. Binds Kubernetes service accounts in named namespaces to GCP identities. Complements the `wif` module (CI identities) with in-cluster runtime identities.

## Inputs

| Name  | Description                       | Type  | Default |
| ----- | --------------------------------- | ----- | ------- |
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_   |

## Outputs

| Name  | Description                     |
| ----- | ------------------------------- |
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (IAM API enabled)
- `gke` module (cluster with Workload Identity enabled)
- `secret-manager` module (secrets for ESO to reference, Phase 4)

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id   = var.project_id
  cluster_name = module.gke.cluster_name
  location     = "europe-west1"

  workload_identity_bindings = {
    external-secrets = {
      namespace            = "external-secrets"
      k8s_service_account  = "external-secrets"
      roles                = ["roles/secretmanager.secretAccessor"]
    }
  }
}
```

## Implementation phase

**Phase 3–4** — CI identities in Phase 3 ([docs/setup/07-github-wif.md](../../../docs/setup/07-github-wif.md)); Workload Identity bindings for ESO and platform SAs in Phase 4 ([docs/setup/10-external-secrets.md](../../../docs/setup/10-external-secrets.md)).
