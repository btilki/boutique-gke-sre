# WIF module

Workload Identity Federation pool, OIDC provider, and CI service account bindings.

## Purpose

Configures **Workload Identity Federation (WIF)** so GitHub Actions can authenticate to GCP **without long-lived service account keys**. Creates a WIF pool and OIDC provider for `token.actions.githubusercontent.com`, a CI service account, and IAM bindings for Artifact Registry push, cosign signing, and (optionally) manifest PR updates. Scoped to the `boutique-gke-sre` repository.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_ |

## Outputs

| Name | Description |
|------|-------------|
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (IAM, IAM Credentials, STS APIs enabled)
- `artifact-registry` module (repository exists for push permissions)
- GitHub repository `boutique-gke-sre` with Actions enabled

## Usage

```hcl
module "wif" {
  source = "../../modules/wif"

  project_id   = var.project_id
  github_org   = var.github_org
  github_repo  = "boutique-gke-sre"
  ar_location  = "europe-west1"
  ar_repo_id   = module.artifact_registry.repository_id
}
```

## Implementation phase

**Phase 3** — WIF, Artifact Registry, CI pipeline skeleton ([docs/setup/07-github-wif.md](../../../docs/setup/07-github-wif.md)).
