# Release notes — boutique-gke-sre vX.Y.Z

**Release date:** YYYY-MM-DD
**Git tag:** `vX.Y.Z`
**Helm chart:** `gitops/apps/boutique` chart version X.Y.Z
**Online Boutique upstream:** `v0.10.5` (or version bumped in this release)
**Redis image:** `7.2-alpine`

---

## Highlights

<!-- 3–5 bullets: what operators and reviewers should care about -->

-

## Application images

| Service  | Digest (sha256 prefix) | Source tag |
| -------- | ---------------------- | ---------- |
| frontend | `abc123…`              | v0.10.5    |
| …        |                        |            |

> Full digests: `gitops/apps/boutique/values-images.yaml` at tag `vX.Y.Z`.

## Platform changes

<!-- Argo CD, Kyverno, ESO, observability, NetworkPolicy -->

-

## Infrastructure (Terraform)

<!-- Modules changed; whether terraform apply required -->

| Module    | Change        | Apply required |
| --------- | ------------- | -------------- |
| _example_ | _description_ | Yes / No       |

## Security & supply chain

- Trivy scan: pass / accepted-risk baseline updated
- cosign: all images signed and attested
- Binary Authorization: no policy change / describe change

## SRE & observability

<!-- SLO, alert, runbook, game-day changes -->

-

## Breaking changes

<!-- Link to MIGRATION.md sections; use "None" if patch release -->

None.

## Known issues

<!-- Honest list; link GitHub issues -->

-

## Upgrade

See [UPGRADE.md](UPGRADE.md) for step-by-step operator instructions.

**Quick path (no breaking changes):**

1. `git checkout vX.Y.Z`
2. Merge any digest PR from CI if images were rebuilt
3. Manual Argo CD sync per [ADR-003](../adr/003-manual-argocd-sync.md)
4. Run smoke validation: [16-smoke-validation.md](../setup/16-smoke-validation.md)

## Rollback

Revert to previous tag `vX.Y.(Z-1)` — [release-strategy.md § Rollback](release-strategy.md#rollback-strategy).

---

**Full changelog:** compare `vX.Y.(Z-1)...vX.Y.Z` on GitHub.
