# Argo CD Helm install

Helm values and install commands for the Argo CD control plane.

## Purpose

Document how Argo CD is installed on the cluster. The actual Helm release is applied during **Phase 4** (see setup guide).

## Inputs

| Input | Description |
|-------|-------------|
| GKE cluster | Private regional cluster from Phase 2 |
| `namespace.yaml` | `argocd` namespace in parent directory |
| Helm chart | `argo/argo-cd` (version pinned in Phase 4) |

## Outputs

| Output | Description |
|--------|-------------|
| Argo CD server | UI and API in `argocd` namespace |
| Application CRDs | `Application`, `AppProject`, etc. |

## Dependencies

- Phase 2: GKE cluster reachable via `kubectl`
- Phase 4 setup: [docs/setup/09-argocd-bootstrap.md](../../../docs/setup/09-argocd-bootstrap.md)

## Usage

Install is performed in Phase 4. Example (values file to be added here):

```bash
# Phase 4 — do not run until cluster and DNS are ready
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f values.yaml
```

After install, apply `../ingress.yaml` and register the root app-of-apps from `../../root-app.yaml`.
