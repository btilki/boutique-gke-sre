# Teardown scripts

Pre-destroy validation and orphan resource detection for Phase 8.

## Purpose

Support safe project teardown documented in [docs/teardown.md](../../docs/teardown.md).

## Scripts

| Script                     | Purpose                                         |
| -------------------------- | ----------------------------------------------- |
| `pre-destroy-checklist.sh` | Verify backups and flag resources still present |
| `orphan-resource-scan.sh`  | Read-only `gcloud` inventory of common orphans  |

## Cadence

| When                                           | Guide                                                                                  |
| ---------------------------------------------- | -------------------------------------------------------------------------------------- |
| Weekly (live project) / pre- and post-teardown | [docs/operations/orphan-scan-cadence.md](../../docs/operations/orphan-scan-cadence.md) |

Report only — **no auto-delete**.

## Usage

```bash
export PROJECT_ID=boutique-gke
./scripts/teardown/orphan-resource-scan.sh
./scripts/teardown/pre-destroy-checklist.sh
```

## Prerequisites

- `gcloud` authenticated with project viewer or editor
- Terraform destroy order followed per [docs/teardown.md](../../docs/teardown.md)

## Further reading

- [scripts/README.md](../README.md)
