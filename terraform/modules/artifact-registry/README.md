# Artifact Registry module

Docker Artifact Registry repository with cleanup and IAM baseline.

## Purpose

Creates a **regional Docker Artifact Registry** repository in `europe-west1` for Online Boutique container images. Images are referenced by **digest only** in GitOps manifests. Supports cleanup policies for untagged images and IAM bindings for the WIF CI service account and GKE Workload Identity pull identities.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_ |

## Outputs

| Name | Description |
|------|-------------|
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (Artifact Registry API enabled)
- GCP project `boutique-gke`

## Usage

```hcl
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id   = var.project_id
  location     = "europe-west1"
  repository_id = "boutique"
  description  = "Online Boutique images — digest-only promotion"
}
```

## Implementation phase

**Phase 3** — WIF, Artifact Registry, CI pipeline skeleton ([docs/setup/08-artifact-registry-binary-auth.md](../../../docs/setup/08-artifact-registry-binary-auth.md)).
