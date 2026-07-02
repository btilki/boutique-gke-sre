# DNS module

Cloud DNS managed zone and A records for boutique storefront and Argo CD hostnames.

## Purpose

Creates a Cloud DNS managed zone for the root domain (e.g. `biroltilki.art`) and A records pointing `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` at the global static ingress IP. Name servers from this module are delegated at the domain registrar.

## Inputs

| Name                | Description                    | Type   | Default                          |
| ------------------- | ------------------------------ | ------ | -------------------------------- |
| `project_id`        | GCP project ID                 | string | required                         |
| `domain`            | Root DNS domain                | string | required                         |
| `static_ip_address` | Global static IP for A records | string | required                         |
| `boutique_hostname` | Storefront FQDN                | string | `boutique.biroltilki.art`        |
| `argocd_hostname`   | Argo CD FQDN                   | string | `argocd.boutique.biroltilki.art` |
| `managed_zone_name` | Cloud DNS zone resource name   | string | `biroltilki-art`                 |
| `ttl`               | Record TTL in seconds          | number | `300`                            |

## Outputs

| Name                | Description                         |
| ------------------- | ----------------------------------- |
| `managed_zone_name` | Cloud DNS zone name                 |
| `name_servers`      | NS records for registrar delegation |
| `boutique_fqdn`     | Boutique A record FQDN              |
| `argocd_fqdn`       | Argo CD A record FQDN               |

## Dependencies

- `ingress-edge` module (static IP address)
- `dns.googleapis.com` API enabled

## Usage

```hcl
module "dns" {
  source = "../../modules/dns"

  project_id        = var.project_id
  domain            = var.domain
  static_ip_address = module.ingress_edge.address
  boutique_hostname = var.boutique_hostname
  argocd_hostname   = var.argocd_hostname
}
```

## Setup guide

→ [05 — Cloud DNS and NS delegation](../../../docs/setup/05-cloud-dns.md)
