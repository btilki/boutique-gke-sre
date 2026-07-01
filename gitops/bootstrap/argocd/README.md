# Argo CD bootstrap

Namespace, Ingress, and install references for the Argo CD GitOps control plane.

## Purpose

Bootstrap manifests for Argo CD on `argocd.boutique.biroltilki.art`. Argo CD reconciles all cluster desired state from this repository.

## Inputs

| Input | Description |
|-------|-------------|
| GKE cluster | Private regional cluster (`boutique-gke`) |
| DNS | `argocd.boutique.biroltilki.art` → static IP (Terraform) |
| TLS | Google-managed certificate on Ingress |

## Outputs

| Output | Description |
|--------|-------------|
| `argocd` namespace | Control-plane namespace |
| Argo CD server | HTTPS UI at https://argocd.boutique.biroltilki.art |
| Sync target | Root app-of-apps in `../root-app.yaml` |

## Dependencies

- Terraform: networking, GKE, DNS, static IP (Phases 1–2)
- Phase 4: Helm install per `install/README.md`

## Usage

1. Apply namespace: `kubectl apply -f namespace.yaml`
2. Install Argo CD via Helm (Phase 4): see `install/README.md`
3. Apply Ingress after cert and static IP are configured: `kubectl apply -f ingress.yaml`
4. Register root Application: `kubectl apply -f ../root-app.yaml`

Manual sync only — see ADR `003-manual-argocd-sync.md`.
