# Boutique environment — Terraform root module

Single GCP project (`boutique-gke`) infrastructure stack.

## Purpose

Wire Terraform modules for the boutique environment. State stored in GCS.

## Inputs

See `variables.tf` and `terraform.tfvars.example`.

## Outputs

See `outputs.tf`:

| Phase                | Outputs                                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------------------------- |
| **1** (topic 03)     | `network_name`, `subnet_name`, `pods_range_name`, `services_range_name`, `enabled_apis`                   |
| **2** (topics 04–06) | `cluster_name`, `cluster_location`, `ingress_static_ip`, `dns_name_servers`, `boutique_url`, `argocd_url` |
| **3** (topic 07)     | `wif_provider_name`, `ci_service_account_email`                                                           |
| **9-C** (topic 19)   | `boutique_uptime_check_id`, `argocd_uptime_check_id`, `backup_plan_id` — only when `enable_*_iac=true`    |

Phase 2 outputs return `null` until the corresponding modules are applied. Monitoring/backup modules default **off** (`enable_monitoring_iac` / `enable_backup_iac` = `false`).

## Monitoring and backup IaC flags

| Variable                | Default | Effect                                      |
| ----------------------- | ------- | ------------------------------------------- |
| `enable_monitoring_iac` | `false` | Uptime checks + optional PagerDuty channel  |
| `pagerduty_service_key` | `""`    | Sensitive; never commit; empty = no channel |
| `enable_backup_iac`     | `false` | GKE Backup plan `boutique-daily`            |

Apply path: [docs/setup/19-monitoring-backup-terraform.md](../../../docs/setup/19-monitoring-backup-terraform.md) (topic 19).

## Dependencies

- GCS backend bucket created (setup guide 02)
- Phase 1: APIs and networking modules (`-target` apply in topic 03)
- Phase 2: GKE, ingress-edge, DNS modules (topics 04–06)

## Usage

**Phase 1 only (topic 03):**

```bash
terraform init
terraform plan \
  -target=module.project_apis \
  -target=module.networking \
  -out=tfplan
terraform apply tfplan
```

**Full stack (after Phase 1):**

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Setup guides: [docs/setup/README.md](../../../docs/setup/README.md)
