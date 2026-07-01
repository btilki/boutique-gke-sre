# Project APIs module

Enables required Google Cloud APIs for boutique-gke-sre in a single project.

## Purpose

Idempotently enable GCP service APIs before other Terraform resources are created. Prevents apply failures from disabled APIs.

## Inputs

| Name         | Description                         | Type           | Default            |
| ------------ | ----------------------------------- | -------------- | ------------------ |
| `project_id` | GCP project ID                      | `string`       | required           |
| `apis`       | List of service API names to enable | `list(string)` | see `variables.tf` |

## Outputs

| Name           | Description                 |
| -------------- | --------------------------- |
| `enabled_apis` | APIs enabled by this module |

## Dependencies

- GCP project exists with billing enabled
- Caller has `serviceusage.services.enable` permission

## Usage

```hcl
module "project_apis" {
  source = "../../modules/project-apis"

  project_id = var.project_id
}
```
