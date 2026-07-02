# Boutique Helm templates

Kubernetes manifests rendered from the Online Boutique Helm chart.

## Purpose

Hold Deployment, Service, Ingress, and supporting templates for all Online Boutique microservices. Templates are added in Phase 5.

## Inputs

| Input                   | Description                                 |
| ----------------------- | ------------------------------------------- |
| `../values.yaml`        | Replicas, resources, probes, ingress host   |
| `../values-images.yaml` | Digest-pinned image references (CI-updated) |

## Outputs

| Output             | Description                                             |
| ------------------ | ------------------------------------------------------- |
| Rendered manifests | Deployments, Services, Ingress for `boutique` namespace |

## Dependencies

- Phase 4 gate complete (Argo CD, Kyverno, ESO, NetworkPolicy)
- Artifact Registry images signed and attested (CI pipeline)

## Usage

```bash
helm template boutique . -f values.yaml -f values-images.yaml
```

Argo CD syncs this chart via `../argocd-apps/boutique-application.yaml`.
