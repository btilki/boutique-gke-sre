# GitOps

Kubernetes desired state for Argo CD: bootstrap, applications, and platform policies.

## Purpose

Deploy and manage cluster workloads from Git using **GitOps** (**Git-based continuous delivery**). No manual `kubectl apply` for production paths after Phase 4 bootstrap.

## Layout

```text
gitops/
├── bootstrap/
│   ├── argocd/
│   │   ├── namespace.yaml
│   │   ├── ingress.yaml
│   │   ├── install/              # Helm install (Phase 4)
│   │   └── README.md
│   ├── external-secrets/
│   │   ├── operator/             # ESO Helm install (Phase 4)
│   │   ├── cluster-secret-store.yaml
│   │   └── README.md
│   ├── root-app.yaml             # App-of-apps entry point
│   └── README.md
├── apps/
│   ├── boutique/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-images.yaml    # digest pins (CI-updated)
│   │   ├── templates/
│   │   └── README.md
│   ├── argocd-apps/
│   │   ├── boutique-application.yaml
│   │   ├── observability-application.yaml
│   │   └── policies-application.yaml
│   └── README.md
├── policies/
│   ├── kyverno/
│   │   ├── require-digest.yaml
│   │   ├── require-probes.yaml
│   │   ├── require-resources.yaml
│   │   ├── require-netpol-labels.yaml
│   │   ├── block-plain-secrets.yaml
│   │   └── README.md
│   ├── network-policies/
│   │   ├── default-deny.yaml
│   │   ├── boutique-allow.yaml
│   │   └── README.md
│   └── README.md
└── README.md
```

| Directory           | Phase | Role                                     |
| ------------------- | ----- | ---------------------------------------- |
| `bootstrap/`        | 4     | Argo CD, ESO, app-of-apps                |
| `policies/`         | 4     | Kyverno, NetworkPolicy (production gate) |
| `apps/boutique/`    | 5     | Online Boutique Helm chart               |
| `apps/argocd-apps/` | 4–6   | Argo CD Application CRs                  |

## Inputs

| Input            | Source                                          |
| ---------------- | ----------------------------------------------- |
| GKE cluster      | Terraform `environments/boutique/` (Phase 2)    |
| Container images | Artifact Registry via CI (`values-images.yaml`) |
| Secrets          | GCP Secret Manager via ESO                      |
| Git repository   | Argo CD source of truth                         |

## Outputs

| Output            | URL / resource                                                |
| ----------------- | ------------------------------------------------------------- |
| Argo CD UI        | `argocd.boutique.biroltilki.art` (**inactive** until rebuild) |
| Storefront        | `boutique.biroltilki.art` (**inactive** until rebuild)        |
| Enforced policies | Kyverno + NetworkPolicy baseline                              |

## Dependencies

- GKE cluster (Phase 2)
- Argo CD installed (Phase 4)
- Phase 4 gate complete before boutique deploy (Phase 5)

## Usage

1. Bootstrap platform: `bootstrap/` per [docs/setup/09-argocd-bootstrap.md](../docs/setup/09-argocd-bootstrap.md)
2. Register root app: `kubectl apply -f bootstrap/root-app.yaml`
3. Manual sync in Argo CD UI at `argocd.boutique.biroltilki.art` (when DNS is active)

Sync order: `policies` → `boutique` → `observability`.
