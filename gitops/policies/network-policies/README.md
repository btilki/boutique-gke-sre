# Network policies

Default-deny and application allow-list NetworkPolicies for micro-segmentation.

## Purpose

Implement zero-trust network segmentation: deny all traffic by default, then allow only required paths between Online Boutique services.

## Inputs

| Input              | File                                   | Description                                    |
| ------------------ | -------------------------------------- | ---------------------------------------------- |
| Default deny       | `default-deny.yaml`                    | Block all ingress/egress per namespace         |
| Allow rules        | `boutique-allow.yaml`                  | East-west + DNS + GLB health checks            |
| Storefront ingress | `boutique-frontend-ingress.yaml`       | External HTTPS to `app: frontend` on port 8080 |
| Observability deny | `observability-default-deny.yaml`      | Default deny in `observability` namespace      |
| OTel ingress       | `observability-collector-ingress.yaml` | OTLP from `boutique` only                      |
| Platform egress    | `observability-platform-egress.yaml`   | DNS + HTTPS egress for observability pods      |
| Namespace labels   | Kyverno `require-netpol-labels`        | Tier label on namespaces                       |

## Outputs

| Output                      | Description                                 |
| --------------------------- | ------------------------------------------- |
| `default-deny-all`          | Baseline deny policy per namespace          |
| `boutique-allow`            | Microservice mesh + health-check ingress    |
| `boutique-frontend-ingress` | Public ingress to frontend pods on TCP 8080 |

## Dependencies

- Phase 4: CNI supports NetworkPolicy (GKE default)
- Kyverno: `require-netpol-labels` policy
- Boutique Helm chart: pod labels matching selectors (Phase 5)

## Usage

Uncomment scaffolds and apply after namespace creation. Synced with policies Application:

```bash
kubectl apply -f default-deny.yaml -f boutique-allow.yaml -f boutique-frontend-ingress.yaml
```

Validate connectivity with game-day scripts in `../../../scripts/game-days/`.
