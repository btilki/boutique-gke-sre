# GKE module

Private regional GKE cluster and autoscaling node pool for Online Boutique on `boutique-gke`.

## Purpose

Provisions a production-style **private regional GKE cluster** in `europe-west1` with Workload Identity, secondary IP ranges for pods and services (from the networking module), and an autoscaling node pool sized for the Boutique microservices workload. Nodes have no public IPs; egress uses Cloud NAT from the VPC module.

## Inputs

| Name                  | Description                     | Type   | Default            |
| --------------------- | ------------------------------- | ------ | ------------------ |
| `project_id`          | GCP project ID                  | string | required           |
| `region`              | Regional cluster location       | string | required           |
| `cluster_name`        | GKE cluster name                | string | `boutique-gke`     |
| `network_name`        | VPC network name                | string | required           |
| `subnet_name`         | GKE subnet name                 | string | required           |
| `pods_range_name`     | Secondary range for pod IPs     | string | required           |
| `services_range_name` | Secondary range for service IPs | string | required           |
| `master_ipv4_cidr`    | Control plane RFC1918 CIDR      | string | `172.16.0.0/28`    |
| `node_pool_name`      | Primary node pool name          | string | `boutique-primary` |
| `machine_type`        | Node machine type               | string | `e2-standard-4`    |
| `min_node_count`      | Min nodes per zone              | number | `1`                |
| `max_node_count`      | Max nodes per zone              | number | `3`                |
| `initial_node_count`  | Initial nodes per zone          | number | `1`                |
| `release_channel`     | GKE release channel             | string | `REGULAR`          |
| `deletion_protection` | Prevent accidental delete       | bool   | `false`            |

## Outputs

| Name                     | Description                           |
| ------------------------ | ------------------------------------- |
| `cluster_name`           | GKE cluster name                      |
| `cluster_location`       | Regional location                     |
| `cluster_endpoint`       | Kubernetes API endpoint (sensitive)   |
| `cluster_ca_certificate` | Cluster CA cert (sensitive)           |
| `workload_identity_pool` | WI pool for K8s SA → GCP IAM bindings |

## Dependencies

- `project-apis` module (Container, Compute APIs enabled)
- `networking` module (VPC, subnet, secondary ranges, Cloud NAT)

## Usage

```hcl
module "gke" {
  source = "../../modules/gke"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  network_name        = module.networking.network_name
  subnet_name         = module.networking.subnet_name
  pods_range_name     = module.networking.pods_range_name
  services_range_name = module.networking.services_range_name
  deletion_protection = var.deletion_protection
}
```

## Setup guide

→ [04 — GKE cluster](../../../docs/setup/04-gke-cluster.md)
