# Runbook: cluster rebuild

**DR asset:** Full GKE cluster — [Architecture §12](../../architecture/overview.md#12-disaster-recovery)

> Used when cluster is lost but Terraform state and Git remain.

## Purpose

Rebuild private GKE cluster and restore GitOps state from Git.

## Prerequisites

- GCS Terraform state intact
- Git repo unchanged

## High-level steps

1. `terraform apply` — VPC (if needed), GKE, DNS, edge
2. Bootstrap Argo CD per [09-argocd-bootstrap.md](../../setup/09-argocd-bootstrap.md)
3. Sync platform policies (Kyverno, ESO, NetworkPolicy)
4. Sync applications; verify HTTPS on both hostnames

## Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

## Further reading

- [bootstrap.md](../../bootstrap.md)
- [setup/19-monitoring-backup-terraform.md](../../setup/19-monitoring-backup-terraform.md) — enable `module.backup` on rebuild
- [teardown.md](../../teardown.md)
