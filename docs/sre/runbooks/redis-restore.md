# Runbook: Redis restore

**DR asset:** Cart Redis state — [Architecture §12](../../architecture/overview.md#12-disaster-recovery)

> Procedures validated in Phase 8 backup/restore.

## Purpose

Restore Redis persistence after data loss or corruption.

## Prerequisites

- Recent GKE Backup or Velero snapshot (documented in Phase 8)
- Maintenance window; expect cart session loss for in-flight users

## High-level steps

1. Scale down `cartservice` to prevent writes
2. Restore Redis volume from backup per backup runbook
3. Verify Redis pod healthy
4. Scale `cartservice` up; smoke test cart flow

## Further reading

- [teardown.md](../../teardown.md) (backup section)
