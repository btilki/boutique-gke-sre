# GitHub Actions workflows

| Workflow                                         | Phase | Purpose                                             |
| ------------------------------------------------ | ----- | --------------------------------------------------- |
| [ci.yml](ci.yml)                                 | 1     | Lint, Terraform validate                            |
| [terraform-plan.yml](terraform-plan.yml)         | 1     | Plan on PR                                          |
| [build-scan-sign.yml](build-scan-sign.yml)       | 3     | Mirror upstream, Trivy, AR push, cosign sign+attest |
| [manifest-digest-pr.yml](manifest-digest-pr.yml) | 3     | Digest promotion PR (after build-scan-sign)         |

See [.github/README.md](../README.md).
