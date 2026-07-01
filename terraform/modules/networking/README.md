# Networking module

VPC, private subnet, Cloud NAT, and baseline firewall rules for a private GKE cluster.

## Purpose

Provides network foundation for private GKE nodes with controlled egress via Cloud NAT and Private Google Access for GCP APIs.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | GCP project ID | `string` | required |
| `region` | GCP region | `string` | required |
| `network_name` | VPC name | `string` | `boutique-vpc` |
| `subnet_name` | Primary subnet name | `string` | `boutique-gke-subnet` |
| `subnet_cidr` | Node subnet CIDR | `string` | `10.10.0.0/20` |
| `pods_cidr` | Secondary range for pods | `string` | `10.20.0.0/16` |
| `services_cidr` | Secondary range for services | `string` | `10.30.0.0/20` |
| `enable_flow_logs` | Enable VPC flow logs on subnet | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | VPC self link |
| `network_name` | VPC name |
| `subnet_id` | Subnet self link |
| `subnet_name` | Subnet name |
| `pods_range_name` | Secondary range name for pods |
| `services_range_name` | Secondary range name for services |
| `router_name` | Cloud Router name |
| `nat_name` | Cloud NAT name |

## Dependencies

- `project-apis` module (compute.googleapis.com enabled)

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  project_id = var.project_id
  region     = var.region
}
```
