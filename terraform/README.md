# Terraform — boutique-gke-sre

GCP **IaC** (**Infrastructure as Code**) for project `boutique-gke`.

## Purpose

Provision VPC, GKE, DNS, IAM, WIF, edge security, and monitoring GCP resources. Kubernetes workloads are deployed via GitOps in `gitops/`.

## Layout

```
terraform/
├── modules/           # Reusable modules
└── environments/
    └── boutique/      # Single project + cluster root module
```

## Dependencies

- GCS state bucket (create manually per `docs/setup/02-terraform-remote-state.md`)
- `gcloud` authenticated with project owner/editor

## Usage

```bash
cd environments/boutique
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Phase 1 scope

- `project-apis` — enable GCP APIs
- `networking` — VPC, subnet, Cloud NAT, firewall baseline

Phase 2+ adds `gke`, `dns`, `wif`, etc.
