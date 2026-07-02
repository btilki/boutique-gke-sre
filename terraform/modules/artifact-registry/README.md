# Artifact Registry module

Docker Artifact Registry repository with cleanup and IAM baseline.

## Purpose

Creates a **regional Docker Artifact Registry** repository in `europe-west1` for Online Boutique container images. Images are referenced by **digest only** in GitOps manifests. Supports cleanup policies for untagged images and IAM bindings for the WIF CI service account and GKE Workload Identity pull identities.

## Inputs

| Name                       | Description                                | Type     | Default                                        |
| -------------------------- | ------------------------------------------ | -------- | ---------------------------------------------- |
| `project_id`               | GCP project ID                             | `string` | —                                              |
| `location`                 | Regional location                          | `string` | `europe-west1`                                 |
| `repository_id`            | Repository ID                              | `string` | `boutique`                                     |
| `description`              | Repository description                     | `string` | Online Boutique images — digest-only promotion |
| `ci_service_account_email` | CI SA for push (`artifactregistry.writer`) | `string` | —                                              |
| `grant_node_pull`          | Grant reader to default Compute SA         | `bool`   | `true`                                         |

## Outputs

| Name              | Description                                     |
| ----------------- | ----------------------------------------------- |
| `repository_id`   | Repository ID                                   |
| `location`        | Regional location                               |
| `repository_name` | Full GCP resource name                          |
| `repository_url`  | Docker path (`europe-west1-docker.pkg.dev/...`) |

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
