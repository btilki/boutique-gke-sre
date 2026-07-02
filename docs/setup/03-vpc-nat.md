# VPC, subnets, and Cloud NAT

## Goal

Private network foundation is provisioned via Terraform: VPC `boutique-vpc`, GKE subnet with pod/service secondary ranges, Cloud Router + Cloud NAT for egress, and baseline firewall rules.

## Why this step is required

Private GKE nodes need a VPC with Private Google Access and NAT for outbound internet (image pulls, external APIs). Pod and service CIDRs must be allocated before the GKE cluster module (Phase 2).

Network layout:

```
boutique-vpc (custom, regional)
└── boutique-gke-subnet (10.10.0.0/20)
    ├── secondary: boutique-pods (10.20.0.0/16)
    └── secondary: boutique-services (10.30.0.0/20)
Cloud Router (boutique-router) + boutique-nat → internet egress for private nodes
```

## Prerequisites

- [01 — GCP project and APIs](01-gcp-project-apis.md)
- [02 — Terraform remote state](02-terraform-remote-state.md) — `terraform init` succeeded
- Repository on disk (clone or copy); `terraform.tfvars` from example
- Terraform ≥ 1.5 installed
- For `make validate`: local Git repo (`git init` or clone), `pre-commit`, and `terraform-docs` — see `Makefile` `install-hooks`

## Commands

**Phase 1 scope:** `main.tf` may list Phase 2 modules (`gke`, `ingress_edge`, `dns`) for later topics. This step applies **only** networking. Always run `terraform plan` first; if the plan includes GKE or DNS, use the targeted apply below.

### 1. Configure variables

```bash
cd terraform/environments/boutique
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if project_id or region differ
```

### 2. Plan and review

```bash
terraform plan \
  -target=module.project_apis \
  -target=module.networking \
  -out=tfplan
```

Review: `module.project_apis`, `time_sleep.wait_for_apis` (dependency), and `module.networking` resources only (Phase 1).

### 3. Apply (Phase 1 only)

```bash
terraform apply tfplan
```

If you prefer not to save a plan file:

```bash
terraform apply \
  -target=module.project_apis \
  -target=module.networking
```

### 4. Capture outputs

After Phase 1 apply, read **Phase 1 outputs only** (Phase 2 outputs are `null` until topics 04–06):

```bash
terraform output network_name
terraform output subnet_name
terraform output pods_range_name
terraform output services_range_name
terraform output enabled_apis
```

Or all outputs (Phase 2 keys show `null` until applied):

```bash
terraform output
```

## Expected output

Apply completes with ~15–20 resources created. Outputs include:

```
network_name = "boutique-vpc"
subnet_name = "boutique-gke-subnet"
pods_range_name = "boutique-pods"
services_range_name = "boutique-services"
```

## Validation

```bash
gcloud compute networks describe boutique-vpc --project=boutique-gke
gcloud compute networks subnets describe boutique-gke-subnet \
  --region=europe-west1 --project=boutique-gke
gcloud compute routers nats describe boutique-nat \
  --router=boutique-router --region=europe-west1 --project=boutique-gke
make validate
```

Expected: VPC `ROUTING_MODE_REGIONAL`, subnet has two secondary ranges, NAT `AUTO_ONLY`.

**Before `make validate`:** install tooling once per machine:

```bash
pip install pre-commit
brew install terraform-docs   # macOS; see terraform-docs releases for Linux
git init                      # or clone — pre-commit requires a Git repo
make install-hooks
```

## Common problems

| Symptom                                    | Cause                                                        | Fix                                                                 |
| ------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------------- |
| CIDR overlap                               | Conflicts with existing VPC                                  | Change CIDRs in `variables.tf` / module defaults                    |
| API not enabled                            | Skipped topic 01                                             | Enable compute API; re-apply                                        |
| `cloudarmor.googleapis.com` 403            | Invalid API name (Cloud Armor uses `compute.googleapis.com`) | Use current repo; create a fresh plan — do not reuse stale `tfplan` |
| `SERVICE_DISABLED` after API enable        | GCP API propagation lag                                      | Re-run plan/apply; repo waits 60s via `time_sleep.wait_for_apis`    |
| Apply failed mid-run                       | Stale saved plan                                             | Delete `tfplan` and run `terraform plan` again before apply         |
| State lock                                 | Concurrent apply                                             | Wait or `terraform force-unlock` with care                          |
| `quota exceeded`                           | Project quotas                                               | Request quota increase in Console                                   |
| `terraform validate` flag `-backend` error | Terraform 1.15+ with old pre-commit config                   | Use `--tf-init-args=-backend=false` in `.pre-commit-config.yaml`    |
| `terraform-docs is required`               | Binary not installed                                         | `brew install terraform-docs`                                       |

## Recovery

```bash
terraform destroy \
  -target=module.networking \
  -target=time_sleep.wait_for_apis
terraform plan \
  -target=module.project_apis \
  -target=module.networking \
  -out=tfplan
terraform apply tfplan
```

Do **not** run untargeted `terraform apply` here — `main.tf` includes Phase 2 modules (GKE, DNS, ingress) not yet applied.

Full destroy order documented in [teardown.md](../teardown.md).

## Best practices

- Keep pod CIDR `/16` for growth headroom
- Enable flow logs (default in module) for incident debugging
- Tag firewall rules consistently for Phase 2 GKE node tags

## Security notes

- No `0.0.0.0/0` ingress to nodes except Google health check ranges
- Private Google Access allows API reachability without public node IPs
- Document CIDRs in [architecture/overview.md](../architecture/overview.md)

## Next step

→ [04 — GKE cluster](04-gke-cluster.md) (Phase 2)

After validation, **commit Phase 1** and confirm before proceeding.
