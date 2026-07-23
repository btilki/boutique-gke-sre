# Orphan resource scan cadence

## Purpose

Reduce cost toil by regularly detecting leftover GCP resources (static IPs, forwarding rules, disks) **without** auto-deletion. Complements [docs/teardown.md](../teardown.md) and [scripts/teardown/orphan-resource-scan.sh](../../scripts/teardown/orphan-resource-scan.sh).

## When to run

| Cadence                          | Context             | Action                                                                                 |
| -------------------------------- | ------------------- | -------------------------------------------------------------------------------------- |
| **Weekly** (project live)        | Day-2 hygiene       | Run scan; file issue if unexpected resources                                           |
| **Pre-destroy**                  | Teardown            | Run scan + [pre-destroy-checklist.sh](../../scripts/teardown/pre-destroy-checklist.sh) |
| **Post-destroy +24h**            | Teardown validation | Re-run scan; expect empty / only intentional leftovers                                 |
| **After failed terraform apply** | Incident            | Scan for partially created edge resources                                              |

## Commands

```bash
export PROJECT_ID=boutique-gke
./scripts/teardown/orphan-resource-scan.sh
```

Read-only: uses `gcloud` inventory. **Never** pipe output into delete scripts without human review.

## Expected outcome

- Live cluster: only expected GKE/LB/DNS-related resources
- After teardown: no billing orphans (static IPs, unused disks, leftover forwarding rules)

## Reporting

1. Paste notable findings into the weekly platform sync notes or open a bug issue
2. Do **not** auto-delete — confirm against Terraform state and GitOps first
3. Link from error-budget review if cost spikes correlate with orphans

## Related

- [day-2-ops.md](day-2-ops.md)
- [scripts/teardown/README.md](../../scripts/teardown/README.md)
- [setup/20-sre-practices-capacity-toil.md](../setup/20-sre-practices-capacity-toil.md) (topic 20)
