# Upgrade guide — boutique-gke-sre

Step-by-step instructions for upgrading a live `boutique-gke` environment to a new platform release.

## Purpose

Safely promote a tagged platform release (Git + images + optional Terraform) without violating GitOps, manual sync, or error-budget policy.

## When to use

- New Git tag `vX.Y.Z` published
- Digest promotion PR merged for new upstream Online Boutique version
- Terraform module upgrade requiring `terraform apply`
- Platform Helm chart bump (Argo CD, Kyverno, ESO, observability)

## Prerequisites

- Bootstrap complete ([bootstrap.md](../bootstrap.md))
- `kubectl`, `gcloud`, `argocd` CLI access
- Argo CD UI: `argocd.boutique.biroltilki.art`
- Error budget reviewed ([error-budget-policy.md](../sre/error-budget-policy.md))
- Maintenance window for checkout-path or infra changes

---

## Upgrade types

| Type           | Scope                                               | Typical trigger          | Downtime risk |
| -------------- | --------------------------------------------------- | ------------------------ | ------------- |
| **Patch**      | Docs, runbooks, alert tuning                        | `v1.0.1`                 | None          |
| **Minor**      | Platform charts, observability, new policies        | `v1.1.0`                 | Low           |
| **Major**      | GKE version, Kyverno breaking, DNS/TLS architecture | `v2.0.0`                 | Medium–high   |
| **Image-only** | Online Boutique upstream bump                       | `upstream_version` in CI | Low (rolling) |
| **Infra**      | Terraform modules                                   | TF PR merged             | Medium        |

---

## Standard upgrade (GitOps / application)

### 1. Pre-upgrade checks

```bash
export PROJECT_ID=boutique-gke
gcloud config set project "${PROJECT_ID}"

# Baseline health
curl -I https://boutique.biroltilki.art
kubectl get nodes
kubectl -n argocd get applications

# Error budget
# Cloud Console → Monitoring → SLOs
```

**Pass:** Storefront HTTP 200/302; nodes Ready; error budget > 25% for risky changes.

### 2. Review release notes

```bash
git fetch --tags
git show vX.Y.Z --stat
# Read docs/release/ notes for tag vX.Y.Z on GitHub Releases
```

Confirm breaking changes and migration steps in [MIGRATION.md](MIGRATION.md).

### 3. Image promotion (if upstream version changed)

```bash
# GitHub → Actions → build-scan-sign → Run workflow
#   upstream_version: <new>
#   redis_tag: <if changed>

# Review and merge digest PR → values-images.yaml
grep '@sha256:' gitops/apps/boutique/values-images.yaml
```

### 4. Sync platform policies (if changed)

```bash
argocd app diff policies
argocd app sync policies --prune
kubectl get clusterpolicy
```

### 5. Sync observability (if changed)

```bash
argocd app sync observability --prune
kubectl -n observability get pods
```

### 6. Sync application

```bash
argocd app diff boutique
argocd app sync boutique --prune
kubectl rollout status deployment/frontend -n boutique --timeout=300s
```

### 7. Post-upgrade validation

```bash
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
kubectl get pods -n boutique
make runbook-lint
```

Full checklist: [16-smoke-validation.md](../setup/16-smoke-validation.md).

---

## Infrastructure upgrade (Terraform)

```bash
git checkout vX.Y.Z
cd terraform/environments/boutique
terraform init
terraform plan -out=tfplan
# Review plan carefully — note GKE version, node pool, IAM changes
terraform apply tfplan
```

After GKE control plane upgrade, verify nodes and re-run GitOps sync steps above.

→ [operations-runbook.md § Upgrades](../operations/operations-runbook.md#upgrades)

---

## Upgrade order (always)

```
Terraform (if required)
  → platform policies (Kyverno, NetworkPolicy)
  → ESO / bootstrap
  → observability
  → boutique application
  → smoke validation
```

Never sync application before policies when Kyverno rules changed.

---

## Rollback

See [release-strategy.md § Rollback](release-strategy.md#rollback-strategy) and [operations/rollback.md](../operations/rollback.md).

---

## Further reading

- [release-strategy.md](release-strategy.md)
- [MIGRATION.md](MIGRATION.md)
- [bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md)
