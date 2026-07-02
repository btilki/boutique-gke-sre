# Backup module

GKE Backup plan and backup storage for lifecycle and restore drills.

## Purpose

Configures **GKE Backup** (or complementary backup storage) for the private cluster in `europe-west1`. Defines backup plans, retention, and IAM for backup/restore operators. Supports validated backup and restore runbooks and teardown readiness — no billing orphans after destroy.

## Inputs

| Name  | Description                       | Type  | Default |
| ----- | --------------------------------- | ----- | ------- |
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_   |

## Outputs

| Name  | Description                     |
| ----- | ------------------------------- |
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (GKE Backup, Storage APIs enabled)
- `gke` module (cluster to protect)
- `iam` module (backup operator service account, if applicable)
- Workloads deployed (Phase 5+) for meaningful restore drills

## Usage

```hcl
module "backup" {
  source = "../../modules/backup"

  project_id   = var.project_id
  location     = "europe-west1"
  cluster_name = module.gke.cluster_name

  backup_plan = {
    name              = "boutique-daily"
    retention_days    = 7
    include_namespaces = ["boutique", "argocd"]
  }
}
```

## Implementation phase

**Phase 8** — Teardown + backup/restore ([docs/teardown.md](../../../docs/teardown.md)).
