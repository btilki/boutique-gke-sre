# IAM matrix — boutique-gke-sre

## Purpose

Map identities to GCP/Kubernetes permissions. Expanded in Phase 3 (WIF) and Phase 4 (Workload Identity for ESO).

## Human operators

| Identity | GCP roles (typical) | K8s access |
|----------|---------------------|------------|
| Platform engineer | `roles/owner` or custom least-privilege on `boutique-gke` | `cluster-admin` via authorized networks / IAP |

## Automation (Phase 3+)

| Identity | Purpose | GCP roles (indicative) |
|----------|---------|------------------------|
| `github-actions@boutique-gke.iam.gserviceaccount.com` | CI build, push, sign | `artifactregistry.writer`, `iam.serviceAccountUser` |
| `terraform-ci@...` (optional) | `terraform plan` in Actions | `roles/viewer` + scoped write for plan-only |

WIF binding: GitHub OIDC `attribute.repository` = `ORG/boutique-gke-sre`.

## Workload Identity (Phase 4+)

| K8s SA | Namespace | GCP SA | Purpose |
|--------|-----------|--------|---------|
| `external-secrets` | `external-secrets` | `eso-reader@boutique-gke...` | `secretmanager.secretAccessor` |

## Principles

- No long-lived keys in Git or GitHub Secrets for GCP
- One SA per automation concern
- Audit via Cloud Audit Logs

## Further reading

- [07 — GitHub WIF](../setup/07-github-wif.md)
- [10 — External Secrets](../setup/10-external-secrets.md)
