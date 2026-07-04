# Contributing

## Principles

- **Git is source of truth** — no manual `kubectl apply` for production paths
- **PR-only manifest changes** — including image digest updates from CI
- **Manual Argo CD sync** — deliberate promotion even on a single cluster
- **No secrets in Git** — Secret Manager + ESO only

## Workflow

1. Branch from `main`
2. Make changes; run `make validate` and `pre-commit run --all-files`
3. Open PR with completed checklist (`.github/PULL_REQUEST_TEMPLATE.md`)
4. Review and merge
5. For deploys: manual Argo CD sync after merge

## Releases

Platform releases use [Semantic Versioning](docs/release/release-strategy.md) tags (`vX.Y.Z`). Tagging triggers `.github/workflows/release.yml`; cluster promotion remains operator-driven.

- [Release strategy](docs/release/release-strategy.md)
- [Upgrade guide](docs/release/UPGRADE.md)
- [Release notes template](docs/release/RELEASE_NOTES_TEMPLATE.md)

## Digest promotion

Image digests are updated by CI in `gitops/apps/boutique/values-images.yaml` via PR. Do not hand-edit tags to `:latest`.

## Terraform

- `terraform plan` runs in CI on PRs touching `terraform/`
- Apply is manual by the operator following `docs/setup/`

## Code owners

See [.github/CODEOWNERS](.github/CODEOWNERS).
