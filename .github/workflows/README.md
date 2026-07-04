# GitHub Actions workflows

CI/CD for **boutique-gke-sre**. Supply-chain workflows (`build-scan-sign`, `mirror-platform-images`) are **manual** (`workflow_dispatch`) unless you add schedule or merge triggers.

| Workflow                                                 | Phase | Purpose                                                     |
| -------------------------------------------------------- | ----- | ----------------------------------------------------------- |
| [ci.yml](ci.yml)                                         | 1+    | Terraform validate, Kyverno tests, digest-only, kubeconform |
| [terraform-plan.yml](terraform-plan.yml)                 | 1     | Terraform plan on PR                                        |
| [build-scan-sign.yml](build-scan-sign.yml)               | 3     | WIF → Trivy → AR push → cosign sign + attest                |
| [manifest-digest-pr.yml](manifest-digest-pr.yml)         | 3     | Digest promotion PR (after build-scan-sign)                 |
| [mirror-platform-images.yml](mirror-platform-images.yml) | 4+    | Mirror OTel/Grafana platform images to AR                   |
| [release.yml](release.yml)                               | 7+    | GitHub Release on tag push `v*` (no auto-deploy)            |

## Templates

| File                                                       | Purpose                     |
| ---------------------------------------------------------- | --------------------------- |
| [../PULL_REQUEST_TEMPLATE.md](../PULL_REQUEST_TEMPLATE.md) | PR checklist                |
| [../ISSUE_TEMPLATE/](../ISSUE_TEMPLATE/)                   | Incident follow-up template |

## Related

- [docs/release/release-strategy.md](../../docs/release/release-strategy.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
