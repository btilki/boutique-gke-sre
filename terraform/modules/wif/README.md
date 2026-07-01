# WIF module

Workload Identity Federation pool, OIDC provider, and CI service account bindings.

## Purpose

Configures **Workload Identity Federation (WIF)** so GitHub Actions can authenticate to GCP **without long-lived service account keys**. Creates a WIF pool and OIDC provider for `token.actions.githubusercontent.com`, a CI service account, and a `workloadIdentityUser` binding scoped to `attribute.repository/<org>/<repo>`. Artifact Registry IAM is granted in topic 08 when the repository exists.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | GCP project ID | `string` | — |
| `github_org` | GitHub org or username | `string` | — |
| `github_repo` | Repository name | `string` | `boutique-gke-sre` |
| `pool_id` | WIF pool ID | `string` | `github-pool` |
| `provider_id` | WIF provider ID | `string` | `github-provider` |
| `ci_service_account_id` | CI SA account ID | `string` | `github-ci` |
| `github_ref` | Optional ref condition (e.g. `refs/heads/main`) | `string` | `null` |

## Outputs

| Name | Description |
|------|-------------|
| `wif_provider_name` | Provider resource name for GitHub secret `GCP_WORKLOAD_IDENTITY_PROVIDER` |
| `ci_service_account_email` | CI SA email for GitHub secret `GCP_SERVICE_ACCOUNT` |
| `workload_identity_pool_name` | Full WIF pool resource name |
| `github_principal_set` | Principal set bound to the CI SA |

## Dependencies

- `project-apis` module (`iam.googleapis.com`, `iamcredentials.googleapis.com`, `sts.googleapis.com`)
- GitHub repository with Actions enabled and OIDC workflow permissions (setup topic 07 Part A)

## Usage

```hcl
module "wif" {
  source = "../../modules/wif"

  project_id  = var.project_id
  github_org  = var.github_org
  github_repo = var.github_repo

  depends_on = [time_sleep.wait_for_apis]
}
```

## Implementation phase

**Phase 3** — [docs/setup/07-github-wif.md](../../../docs/setup/07-github-wif.md)
