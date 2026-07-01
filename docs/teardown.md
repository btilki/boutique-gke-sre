# Teardown — boutique-gke-sre

## Purpose

Safely decommission all boutique-gke-sre resources and stop billing with **zero orphan** forwarding rules, IPs, clusters, or disks.

## When to use

- End of portfolio demo / learning period
- Rebuild from scratch after failed state
- Validating Phase 8 lifecycle documentation

**Do not run** on a cluster you intend to keep without reading destroy order.

## Prerequisites

- Owner/editor on GCP project `boutique-gke`
- `kubectl` access if cluster still exists
- Backup completed if Redis/cart data matters ([sre/runbooks/redis-restore.md](sre/runbooks/redis-restore.md))
- [scripts/teardown/pre-destroy-checklist.sh](../scripts/teardown/pre-destroy-checklist.sh)

## Architecture

Teardown reverses bootstrap: GitOps workloads → load balancers → cluster → network → DNS → optional state bucket.

```
Argo Apps deleted → Ingress/LB released → GKE cluster destroyed
  → terraform destroy (VPC, NAT, DNS, IPs) → orphan scan → billing check
```

## Step-by-step implementation

1. **Scale down applications** — Delete or sync-to-empty Argo CD Applications: `boutique`, `observability`, `policies`
2. **Remove Ingress** — Ensure Kubernetes Ingress/Services deleted so GCE LB releases
3. **Wait** — Forwarding rules and backends can take 5–15 minutes to clear
4. **Drain decision** — Confirm PVC retention policy for Redis (backup or discard)
5. **Pre-check:**
   ```bash
   ./scripts/teardown/pre-destroy-checklist.sh
   ```
6. **Terraform destroy:**
   ```bash
   cd terraform/environments/boutique
   terraform destroy
   ```
7. **Orphan scan:**
   ```bash
   ./scripts/teardown/orphan-resource-scan.sh
   ```
8. **State bucket** — Delete `gs://boutique-gke-tfstate` last if desired (optional retain for audit)

## Validation

```bash
gcloud compute instances list --project=boutique-gke
gcloud container clusters list --project=boutique-gke
gcloud compute forwarding-rules list --project=boutique-gke
gcloud compute addresses list --global --project=boutique-gke
dig +short boutique.biroltilki.art
```

**Expected:** Empty lists; DNS no longer points to your IP (or NXDOMAIN after zone delete).

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `terraform destroy` fails on LB | Ingress still exists | `kubectl delete ingress --all -A`; wait |
| Orphan global IP | Manual address not in TF | `gcloud compute addresses delete` |
| NAT/router dependency | Order | Destroy cluster first; see module README |
| Still billed for GKE | Cluster remains | `gcloud container clusters list` |

## Common mistakes

- Destroying VPC while cluster exists
- Deleting state bucket before successful destroy (lose tracking)
- Leaving static IP reserved ($$ monthly)

## Best practices

- Run orphan scan twice (immediate + 24h later)
- Document destroy date in a postmortem-style note for portfolio records
- Export Argo CD app manifests from Git — Git remains source of truth

## Production considerations

- RTO for full rebuild: hours — see [cluster-rebuild runbook](sre/runbooks/cluster-rebuild.md)
- GKE Backup snapshots may incur storage until deleted

## Security considerations

- Revoke WIF bindings and CI service accounts if repo retired
- Remove PagerDuty integration keys from Secret Manager

## Further reading

- [setup/16-smoke-validation.md](setup/16-smoke-validation.md) (pre-teardown checklist inverse)
- [implementation/roadmap.md](implementation/roadmap.md) Phase 8
- [bootstrap.md](bootstrap.md) — rebuild path
