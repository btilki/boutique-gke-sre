# GitOps bootstrap

Platform components installed before application workloads: Argo CD, External Secrets, app-of-apps entry point.

## Purpose

Bootstrap the GitOps control plane and secret integration layer. Everything under `gitops/apps/` and `gitops/policies/` is reconciled via Argo CD after bootstrap completes.

## Inputs

| Input             | Description                           |
| ----------------- | ------------------------------------- |
| GKE cluster       | Private regional cluster from Phase 2 |
| Git repository    | This repo as Argo CD source           |
| Terraform outputs | DNS, static IPs, IAM for ESO          |

## Outputs

| Output   | Description                                         |
| -------- | --------------------------------------------------- |
| Argo CD  | `argocd/` — namespace, Ingress, Helm install        |
| ESO      | `external-secrets/` — operator + ClusterSecretStore |
| Root app | `root-app.yaml` — app-of-apps Application CR        |

## Dependencies

- Phases 1–2: Terraform foundation + GKE
- Phase 4 gate: Argo CD, ESO, Kyverno, NetworkPolicy before app deploy

## Usage

```text
1. argocd/          — namespace → Helm install → ingress (topic 09)
2. external-secrets/ — ESO Helm install → ClusterSecretStore (topic 10)
3. root-app.yaml    — kubectl apply once; sync children from Argo CD UI
```

See [docs/setup/09-argocd-bootstrap.md](../../docs/setup/09-argocd-bootstrap.md) for the ordered bootstrap sequence (Argo CD → ESO → root app).
