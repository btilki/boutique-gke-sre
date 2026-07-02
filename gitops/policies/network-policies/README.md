# Network policies

Default-deny and application allow-list NetworkPolicies for micro-segmentation.

## Purpose

Implement zero-trust network segmentation: deny all traffic by default, then allow only required paths between Online Boutique services.

## Inputs

| Input            | File                            | Description                                      |
| ---------------- | ------------------------------- | ------------------------------------------------ |
| Default deny     | `default-deny.yaml`             | Block all ingress/egress per namespace           |
| Allow rules      | `boutique-allow.yaml`           | Service-to-service paths in `boutique` namespace |
| Namespace labels | Kyverno `require-netpol-labels` | Tier label on namespaces                         |

## Outputs

| Output             | Description                                       |
| ------------------ | ------------------------------------------------- |
| `default-deny-all` | Baseline deny policy per namespace                |
| `boutique-allow`   | Explicit allow rules for storefront microservices |

## Dependencies

- Phase 4: CNI supports NetworkPolicy (GKE default)
- Kyverno: `require-netpol-labels` policy
- Boutique Helm chart: pod labels matching selectors (Phase 5)

## Usage

Uncomment scaffolds and apply after namespace creation. Synced with policies Application:

```bash
kubectl apply -f default-deny.yaml -f boutique-allow.yaml
```

Validate connectivity with game-day scripts in `../../../scripts/game-days/`.
