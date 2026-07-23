# Online Boutique Helm chart

GitOps packaging for Google Online Boutique on the boutique GKE cluster.

## Purpose

Deploy all Online Boutique microservices with digest-pinned images, probes, resource limits, and HTTPS ingress at `boutique.biroltilki.art`.

## Services

Eleven workloads (upstream **v0.10.5** mirrored from `us-central1-docker.pkg.dev/google-samples/microservices-demo`):

| Key                                                                                                                                                                     | Type                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `frontend`                                                                                                                                                              | HTTP storefront                       |
| `adservice`, `cartservice`, `checkoutservice`, `currencyservice`, `emailservice`, `paymentservice`, `productcatalogservice`, `recommendationservice`, `shippingservice` | gRPC microservices                    |
| `redis-cart`                                                                                                                                                            | Cart persistence (`redis:7.2-alpine`) |

## Inputs

| Input                | Description                         |
| -------------------- | ----------------------------------- |
| `values.yaml`        | Application configuration (Phase 5) |
| `values-images.yaml` | Image digests updated by CI         |
| `templates/`         | Helm templates for workloads        |

## Outputs

| Output                         | Description                                                |
| ------------------------------ | ---------------------------------------------------------- |
| `boutique` namespace workloads | 11 Deployments + Services                                  |
| HPA                            | `frontend`, `checkoutservice` (CPU, min 2 / max 6)         |
| PDB                            | `frontend`, `checkoutservice`, `cartservice`, `redis-cart` |
| Ingress                        | Public storefront on `boutique.biroltilki.art`             |
| ManagedCertificate             | Google-managed TLS for storefront hostname                 |

## Reliability defaults

| Workload          | Replicas                      | HPA                   | PDB               |
| ----------------- | ----------------------------- | --------------------- | ----------------- |
| `frontend`        | 2 (HPA-managed)               | CPU 70%, min 2, max 6 | `minAvailable: 1` |
| `checkoutservice` | 2 (HPA-managed)               | CPU 70%, min 2, max 6 | `minAvailable: 1` |
| `cartservice`     | 2                             | —                     | `minAvailable: 1` |
| `redis-cart`      | **1** (single-instance Redis) | —                     | `minAvailable: 1` |
| Other services    | 1                             | —                     | —                 |

`redis-cart` stays at one replica: ClusterIP + multiple Redis pods would split cart state without Redis HA.

## Dependencies

- Phase 4: Argo CD, Kyverno policies, NetworkPolicies, ESO
- CI: [`.github/workflows/build-scan-sign.yml`](../../../.github/workflows/build-scan-sign.yml) (mirror → Trivy → AR → cosign) + [`manifest-digest-pr.yml`](../../../.github/workflows/manifest-digest-pr.yml)
- Binary Authorization at deploy time
- Pod `securityContext` hardened per upstream v0.10.5 (`global.podSecurityContext` in `values.yaml`)

## Usage

```bash
helm template boutique . -f values.yaml -f values-images.yaml | kubectl apply --dry-run=client -f -
```

Production path: Argo CD manual sync via [`../argocd-apps/boutique-application.yaml`](../argocd-apps/boutique-application.yaml).

## Local validation

Same checks CI runs (from repo root):

```bash
./tests/manifest/digest-only.sh
./tests/manifest/boutique-kyverno.sh   # requires kyverno CLI
./tests/manifest/kubeconform.sh        # requires kubeconform + helm
```

## Setup guide

Step-by-step deploy, bootstrap images, and validation: [docs/setup/12-boutique-deploy.md](../../../docs/setup/12-boutique-deploy.md)
