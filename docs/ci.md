# CI contract — boutique-gke-sre

Audience: Implementer or reviewer · Topics 07–08 · 12 · ADR [002](adr/002-wif-over-sa-keys.md), [003](adr/003-manual-argocd-sync.md) · Workflows [`.github/workflows/`](../.github/workflows/README.md)

## After teardown

The closed pilot left no live Artifact Registry and no live WIF binding. Rebuild topics 07–08 before you expect `build-scan-sign` to succeed.

Workflow YAML stays in Git under [`.github/workflows/`](../.github/workflows/). After a rebuild, run supply-chain jobs with `workflow_dispatch` — see [setup/12-boutique-deploy.md](setup/12-boutique-deploy.md).

## At a glance

|              |                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------ |
| Git          | GitHub (source of truth for Argo CD)                                                       |
| CI           | GitHub Actions + WIF to GCP                                                                |
| Default path | Mirror Boutique v0.10.5 → Trivy CRITICAL/HIGH → AR push → cosign sign + attest → digest PR |
| Hard rule    | **CI never syncs Argo** — digest PRs only; operators sync by hand                          |

## Hard rules

| Rule                                                  | Detail                                                                    |
| ----------------------------------------------------- | ------------------------------------------------------------------------- |
| No long-lived GCP SA JSON keys for CI                 | WIF (ADR-002)                                                             |
| Images are mirrored, not rebuilt from Boutique source | `build-scan-sign.yml`                                                     |
| Trivy fails CRITICAL and HIGH                         | Same workflow                                                             |
| cosign signs and attests by digest                    | Key in GitHub secrets — pilot limit in [pilot-claims.md](pilot-claims.md) |
| Successful path opens a digest PR only                | Digests in `gitops/apps/boutique/values-images.yaml`                      |
| CI never deploys to the cluster                       | No `kubectl apply`, `helm upgrade`, or `argocd sync` (ADR-003)            |

## Pipeline map

| Workflow                     | Role                                                                      | Setup             |
| ---------------------------- | ------------------------------------------------------------------------- | ----------------- |
| `ci.yml`                     | Terraform validate, runbook lint, Kyverno tests, digest-only, kubeconform | Every PR          |
| `terraform-plan.yml`         | Terraform plan on PR                                                      | Topic 01+         |
| `build-scan-sign.yml`        | Mirror, Trivy, push, cosign (`workflow_dispatch`)                         | Topics 07–08 · 12 |
| `manifest-digest-pr.yml`     | Digest promotion PR after a green build                                   | Topic 12          |
| `mirror-platform-images.yml` | Mirror OTel/Grafana platform images to AR                                 | Topic 12+         |
| `release.yml`                | GitHub Release on tag `v*` (no auto-deploy)                               | Topic 16+         |

## Where to go next

| Need                                       | Open                                                                                   |
| ------------------------------------------ | -------------------------------------------------------------------------------------- |
| Workflow file list                         | [`.github/workflows/README.md`](../.github/workflows/README.md)                        |
| WIF setup                                  | [setup/07-github-wif.md](setup/07-github-wif.md)                                       |
| Artifact Registry and Binary Authorization | [setup/08-artifact-registry-binary-auth.md](setup/08-artifact-registry-binary-auth.md) |
| Mirror, digest, Boutique sync              | [setup/12-boutique-deploy.md](setup/12-boutique-deploy.md)                             |
| Supply-chain controls                      | [security/supply-chain.md](security/supply-chain.md)                                   |
| Rollback after a bad digest                | [operations/rollback.md](operations/rollback.md)                                       |
| What the pilot proved                      | [pilot-claims.md](pilot-claims.md)                                                     |
