# Backup module

GKE Backup plan for lifecycle and restore drills (Phase 9-C).

## Purpose

Configures a scheduled **GKE Backup** plan for the private boutique cluster:

| Setting     | Default                               |
| ----------- | ------------------------------------- |
| Plan name   | `boutique-daily`                      |
| Schedule    | `0 3 * * *` (daily 03:00 UTC)         |
| Retention   | 7 days (`backup_retain_days`)         |
| Delete lock | 1 day                                 |
| Namespaces  | `boutique`, `argocd`, `observability` |
| Volume data | included                              |
| Secrets     | included                              |

Supports restore procedures in [redis-restore.md](../../../docs/sre/runbooks/redis-restore.md), [cluster-rebuild.md](../../../docs/sre/runbooks/cluster-rebuild.md), and [teardown.md](../../../docs/teardown.md).

## Inputs

| Name                      | Description                         | Type           | Default                         |
| ------------------------- | ----------------------------------- | -------------- | ------------------------------- |
| `project_id`              | GCP project ID                      | `string`       | —                               |
| `location`                | Plan region (match cluster)         | `string`       | —                               |
| `cluster_id`              | `projects/…/locations/…/clusters/…` | `string`       | —                               |
| `backup_plan_name`        | Plan resource name                  | `string`       | `boutique-daily`                |
| `include_namespaces`      | Namespaces to back up               | `list(string)` | boutique, argocd, observability |
| `include_volume_data`     | Include PVC data                    | `bool`         | `true`                          |
| `include_secrets`         | Include Secrets                     | `bool`         | `true`                          |
| `backup_retain_days`      | Retention days                      | `number`       | `7`                             |
| `backup_delete_lock_days` | Min days before delete              | `number`       | `1`                             |
| `cron_schedule`           | Cron (UTC)                          | `string`       | `0 3 * * *`                     |
| `deactivated`             | Pause new backups                   | `bool`         | `false`                         |
| `labels`                  | Resource labels                     | `map(string)`  | terraform / boutique-gke-sre    |

## Outputs

| Name                   | Description        |
| ---------------------- | ------------------ |
| `backup_plan_id`       | Full plan ID       |
| `backup_plan_name`     | Plan name          |
| `backup_plan_location` | Location           |
| `backup_plan_uid`      | UID                |
| `include_namespaces`   | Covered namespaces |

## Dependencies

- `project-apis` — `gkebackup.googleapis.com` enabled
- `gke` — cluster must exist; pass full `cluster_id`
- Meaningful restore drills need workloads (topic 12+)

## Usage

```hcl
module "backup" {
  source = "../../modules/backup"

  project_id = var.project_id
  location   = var.region
  cluster_id = "projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}"

  include_namespaces = ["boutique", "argocd", "observability"]
  backup_retain_days = 7
}
```

Environment wiring (topic 19): `enable_backup_iac` with `count` in `environments/boutique`.

## Teardown notes

Before `terraform destroy`, set `deactivated = true` or delete backup snapshots that would block destroy / incur storage cost. See [docs/teardown.md](../../../docs/teardown.md).

## Setup guide

[docs/setup/19-monitoring-backup-terraform.md](../../../docs/setup/19-monitoring-backup-terraform.md) (created in topic 19).

## Implementation phase

**Phase 9-C** — after GKE exists; optional on rebuild alongside topics 17–18.
