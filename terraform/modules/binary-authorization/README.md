# Binary Authorization module

Attestor, note, and deploy-time image policy for GKE.

## Purpose

Enforces **Binary Authorization** on the private GKE cluster so only **cosign-signed and attested** images from the project Artifact Registry can run. Defines an attestor (linked to cosign key material or Cloud KMS), a policy note, and a cluster admission policy. Must be validated in Phase 3 before Boutique deploy in Phase 5.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_ |

## Outputs

| Name | Description |
|------|-------------|
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (Binary Authorization API enabled)
- `gke` module (cluster to attach policy)
- `artifact-registry` module (allowed image repository)
- `wif` module (CI cosign signing workflow produces attestations)

## Usage

```hcl
module "binary_authorization" {
  source = "../../modules/binary-authorization"

  project_id   = var.project_id
  cluster_name = module.gke.cluster_name
  location     = "europe-west1"
  ar_location  = module.artifact_registry.location
  ar_repo_id   = module.artifact_registry.repository_id
}
```

## Implementation phase

**Phase 3** — WIF, Artifact Registry, CI pipeline skeleton ([docs/setup/08-artifact-registry-binary-auth.md](../../../docs/setup/08-artifact-registry-binary-auth.md)).
