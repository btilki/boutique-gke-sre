# Runbook: Redis restore

**DR asset:** Cart Redis state — [Architecture §12](../../architecture/overview.md#12-disaster-recovery)

> Procedures validated in Phase 8 backup/restore.

## Purpose

Restore Redis persistence after data loss or corruption.

## Prerequisites

- Recent GKE Backup (plan from `terraform/modules/backup` when `enable_backup_iac=true` — topic 19) or documented snapshot
- Maintenance window; expect cart session loss for in-flight users

## High-level steps

1. Scale down `cartservice` to prevent writes
2. Restore Redis volume / namespace from GKE Backup per Console or `gcloud container backup-restore`
3. Verify Redis pod healthy
4. Scale `cartservice` up; smoke test cart flow

## Further reading

- [setup/19-monitoring-backup-terraform.md](../../setup/19-monitoring-backup-terraform.md)
- [teardown.md](../../teardown.md) (backup section)
