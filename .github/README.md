# GitHub — CI/CD and templates

## Purpose

GitHub Actions workflows, PR templates, and CODEOWNERS.

## Workflows

| Workflow | Phase | Purpose |
|----------|-------|---------|
| `ci.yml` | 1 | Lint and validate |
| `terraform-plan.yml` | 1 | Terraform plan on PR |

Phase 3 adds `build-scan-sign.yml` and `manifest-digest-pr.yml`.
