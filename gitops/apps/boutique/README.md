# Online Boutique Helm chart

GitOps packaging for Google Online Boutique on the boutique GKE cluster.

## Purpose

Deploy all Online Boutique microservices with digest-pinned images, probes, resource limits, and HTTPS ingress at https://boutique.biroltilki.art.

## Inputs

| Input                | Description                         |
| -------------------- | ----------------------------------- |
| `values.yaml`        | Application configuration (Phase 5) |
| `values-images.yaml` | Image digests updated by CI         |
| `templates/`         | Helm templates for workloads        |

## Outputs

| Output                         | Description                                       |
| ------------------------------ | ------------------------------------------------- |
| `boutique` namespace workloads | Frontend, cart, checkout, and supporting services |
| Ingress                        | Public storefront on `boutique.biroltilki.art`    |

## Dependencies

- Phase 4: Argo CD, Kyverno policies, NetworkPolicies, ESO
- CI: `build-scan-sign.yml` + `manifest-digest-pr.yml`
- Binary Authorization at deploy time

## Usage

```bash
helm template boutique . -f values.yaml -f values-images.yaml | kubectl apply --dry-run=client -f -
```

Production path: Argo CD manual sync via `../argocd-apps/boutique-application.yaml`.
