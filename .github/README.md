# GitHub — CI/CD and templates

> **Project overview (repo homepage):** [../README.md](../README.md) · [../PORTFOLIO.md](../PORTFOLIO.md)

This file documents the `.github/` folder only. GitHub renders **[README.md](../README.md)** at the repository root — that is the portfolio landing page, not this file.

## Purpose

GitHub Actions workflows, PR/issue templates, and CODEOWNERS.

## Workflows

Full detail: [workflows/README.md](workflows/README.md)

| Workflow                                                           | Phase | Purpose                                                     |
| ------------------------------------------------------------------ | ----- | ----------------------------------------------------------- |
| [ci.yml](workflows/ci.yml)                                         | 1+    | Terraform validate, Kyverno tests, digest-only, kubeconform |
| [terraform-plan.yml](workflows/terraform-plan.yml)                 | 1     | Terraform plan on PR                                        |
| [build-scan-sign.yml](workflows/build-scan-sign.yml)               | 3     | WIF → Trivy → AR push → cosign sign + attest                |
| [manifest-digest-pr.yml](workflows/manifest-digest-pr.yml)         | 3     | Digest promotion PR after build                             |
| [mirror-platform-images.yml](workflows/mirror-platform-images.yml) | 4+    | Mirror OTel/Grafana images to AR                            |
| [release.yml](workflows/release.yml)                               | 7+    | GitHub Release on SemVer tag `v*`                           |

Supply-chain workflows (`build-scan-sign`, `mirror-platform-images`) are **manual** (`workflow_dispatch`) unless you add schedule/merge triggers.

## Templates

| File                                                 | Purpose                     |
| ---------------------------------------------------- | --------------------------- |
| [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) | PR checklist                |
| [ISSUE_TEMPLATE/](ISSUE_TEMPLATE/)                   | Incident follow-up template |

## Related

- [docs/release/release-strategy.md](../docs/release/release-strategy.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
