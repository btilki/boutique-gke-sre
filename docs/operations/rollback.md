# Rollback procedures

## GitOps rollback (preferred)

1. Revert bad commit on `main` (or restore previous digest in `values-images.yaml`)
2. Merge revert PR
3. Manual Argo CD sync

→ [Runbook: bad deploy rollback](../sre/runbooks/bad-deploy-rollback.md)

## Helm / Argo history rollback

Use Argo CD UI **History and rollback** only when Git revert is slower; prefer Git as source of truth.

## Terraform rollback

- Revert Terraform PR; `terraform plan` then `terraform apply`
- State recovery: GCS object versioning

## Further reading

- [ADR 003 — Manual Argo CD sync](../adr/003-manual-argocd-sync.md)
