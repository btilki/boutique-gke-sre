# GitOps applications

Helm charts and Argo CD Application CRs for workloads reconciled from Git.

## Purpose

Define deployable applications and how Argo CD discovers them. Child Applications are referenced by the root app-of-apps in `../bootstrap/root-app.yaml`.

## Inputs

| Input | Description |
|-------|-------------|
| `boutique/` | Online Boutique Helm chart |
| `argocd-apps/` | Application CRs for boutique, observability, policies |
| Argo CD | Root sync from `../bootstrap/root-app.yaml` |

## Outputs

| Output | Description |
|--------|-------------|
| `boutique` Application | Storefront workloads (Phase 5) |
| `observability` Application | OTel, Prometheus, Grafana (Phase 6) |
| `policies` Application | Kyverno + NetworkPolicy (Phase 4) |

## Dependencies

- `../bootstrap/` — Argo CD installed and root app registered
- Phase 4 gate before boutique deploy

## Usage

After bootstrap, sync `boutique-root` in Argo CD UI, then sync child apps manually:

```text
policies        → Phase 4 (required before boutique)
boutique        → Phase 5
observability   → Phase 6
```
