# Migration guide — boutique-gke-sre

Documented breaking changes and required operator actions when upgrading across major or minor platform versions.

## Purpose

Provide explicit migration steps when a release cannot be applied by sync alone. Pair every breaking change with validation and rollback.

## When to use

- Release notes list breaking changes for target version
- `MIGRATION.md` section referenced from GitHub Release
- Major version bump (`v1.x` → `v2.x`)

## Prerequisites

- Read target release notes on GitHub
- Backup state if release touches Redis or Terraform ([operations-runbook.md](../operations/operations-runbook.md))
- Maintenance window scheduled

---

## Active migrations

> Add a new section per breaking release. Archive resolved migrations to git history.

### Template (copy for each breaking release)

#### vX.Y.Z — Short title

**Breaking:** What stopped working or changed behavior.

**Affected:** terraform / gitops / observability / docs

**Migration steps:**

1. Step one with commands
2. Step two
3. Validation

**Rollback:** How to revert if migration fails.

**Validation:**

```bash
# commands
```

---

## Example: Manual Argo CD sync (baseline — not a migration)

This is architectural policy, not a version migration. All releases assume [ADR-003](../adr/003-manual-argocd-sync.md): no auto-sync on production Applications.

---

## Example: Online Boutique upstream bump (v0.10.4 → v0.10.5)

**Breaking:** Old image paths `gcr.io/google-samples/microservices-demo` removed.

**Migration steps:**

1. Run `build-scan-sign` with `upstream_version: v0.10.5`
2. Merge digest PR
3. Update `.github/trivy/upstream-mirror.trivyignore` if Trivy baseline changed
4. Manual Argo CD sync `boutique`

**Validation:** [12-boutique-deploy.md](../setup/12-boutique-deploy.md)

---

## Example: Cosign / Binary Authorization key rotation

**Breaking:** New images fail Binary Authorization until attestor updated.

**Migration steps:**

1. Generate new cosign key pair
2. Update GitHub Secrets `COSIGN_PRIVATE_KEY`, `COSIGN_PASSWORD`
3. Update `cosign_public_key_pem` in `terraform.tfvars`
4. `terraform apply -target=module.binary_authorization`
5. Re-run `build-scan-sign` and merge digest PR
6. Sync boutique

**Rollback:** Revert Terraform cosign key; re-sign images with previous key.

---

## Compatibility matrix (reference)

| Platform release | GKE (min) | Online Boutique | Argo CD chart | Kyverno |
| ---------------- | --------- | --------------- | ------------- | ------- |
| v1.0.x           | 1.28+     | v0.10.5         | 7.x           | 1.12+   |

Update this table when releasing versions that change minimum dependencies.

---

## Further reading

- [UPGRADE.md](UPGRADE.md)
- [release-strategy.md](release-strategy.md)
- [docs/adr/](../adr/)
