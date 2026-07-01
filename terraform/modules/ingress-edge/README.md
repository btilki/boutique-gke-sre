# Ingress edge module

Global static IPv4 address reserved for GCE Ingress load balancers serving boutique and Argo CD hostnames.

## Purpose

Reserves a **global static external IP** named `boutique-ingress-ip` used by Kubernetes Ingress annotations (`kubernetes.io/ingress.global-static-ip-name`). Stable IP allows Cloud DNS A records and Google-managed TLS certificates to provision without churn when Ingress controllers reconcile.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | GCP project ID | string | required |
| `address_name` | GCP address resource name | string | `boutique-ingress-ip` |
| `description` | Resource description | string | Global static IP for boutique + argocd ingress |

## Outputs

| Name | Description |
|------|-------------|
| `address_name` | Static IP resource name (Ingress annotation value) |
| `address` | Reserved IPv4 address (DNS A record target) |

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
metadata:
  annotations:
    kubernetes.io/ingress.global-static-ip-name: boutique-ingress-ip
```

## Setup guide

→ [06 — Static ingress IP and TLS](../../../docs/setup/06-ingress-tls.md)
