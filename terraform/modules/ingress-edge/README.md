# Ingress edge module

Two global static IPv4 addresses reserved for GCE Ingress load balancers — one per public hostname.

## Purpose

GCE Ingress binds a **named global address** via `kubernetes.io/ingress.global-static-ip-name`. Boutique and Argo CD use **separate Ingress objects** (and Cloud Armor policies), so each hostname needs its own IP:

| Resource name         | Hostname                         | Ingress                                |
| --------------------- | -------------------------------- | -------------------------------------- |
| `boutique-ingress-ip` | `boutique.biroltilki.art`        | Boutique Helm                          |
| `argocd-ingress-ip`   | `argocd.boutique.biroltilki.art` | `gitops/bootstrap/argocd/ingress.yaml` |

Stable IPs keep Cloud DNS A records and Google-managed TLS certificates from churning when Ingress controllers reconcile.

## Inputs

| Name                  | Description                          | Type   | Default                                             |
| --------------------- | ------------------------------------ | ------ | --------------------------------------------------- |
| `project_id`          | GCP project ID                       | string | required                                            |
| `address_name`        | Storefront GCP address resource name | string | `boutique-ingress-ip`                               |
| `description`         | Storefront address description       | string | Global static IP for boutique.biroltilki.art        |
| `argocd_address_name` | Argo CD GCP address resource name    | string | `argocd-ingress-ip`                                 |
| `argocd_description`  | Argo CD address description          | string | Global static IP for argocd.boutique.biroltilki.art |

## Outputs

| Name                  | Description                                            |
| --------------------- | ------------------------------------------------------ |
| `address_name`        | Storefront IP resource name (Ingress annotation value) |
| `address`             | Storefront IPv4 (DNS A record for boutique hostname)   |
| `argocd_address_name` | Argo CD IP resource name (Ingress annotation value)    |
| `argocd_address`      | Argo CD IPv4 (DNS A record for argocd hostname)        |

## Dependencies

- `compute.googleapis.com` API enabled

## Usage

```hcl
module "ingress_edge" {
  source = "../../modules/ingress-edge"

  project_id = var.project_id
}
```

Reference in Kubernetes:

```yaml
# Boutique Ingress
kubernetes.io/ingress.global-static-ip-name: boutique-ingress-ip

# Argo CD Ingress
kubernetes.io/ingress.global-static-ip-name: argocd-ingress-ip
```

## Setup guide

→ [06 — Static ingress IP and TLS](../../../docs/setup/06-ingress-tls.md)
