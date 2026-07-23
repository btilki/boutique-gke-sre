# Monitoring module

Cloud Monitoring uptime checks and PagerDuty notification channel (Phase 9-C).

## Purpose

Provisions **GCP-native** monitoring primitives for boutique-gke-sre:

| Resource             | Name / target                                                           |
| -------------------- | ----------------------------------------------------------------------- |
| HTTPS uptime check   | `boutique-storefront` → `boutique.biroltilki.art` (60s)                 |
| HTTPS uptime check   | `argocd-ui` → `argocd.boutique.biroltilki.art/healthz` (300s)           |
| Notification channel | PagerDuty (optional — created only when `pagerduty_service_key` is set) |

**Not in this module (C1):** Cloud Monitoring SLOs and multi-window burn-rate alert policies. Those stay in `observability/monitoring/` + `scripts/create-*-burn-rate-policies.sh` until a future C2 migration. After apply, attach the PagerDuty channel to alert policies via `scripts/attach-pagerduty-channel.sh` or Console.

## Inputs

| Name                     | Description                                         | Type           | Default                                            |
| ------------------------ | --------------------------------------------------- | -------------- | -------------------------------------------------- |
| `project_id`             | GCP project ID                                      | `string`       | —                                                  |
| `boutique_hostname`      | Storefront FQDN                                     | `string`       | `boutique.biroltilki.art`                          |
| `argocd_hostname`        | Argo CD FQDN                                        | `string`       | `argocd.boutique.biroltilki.art`                   |
| `argocd_health_path`     | Argo health path                                    | `string`       | `/healthz`                                         |
| `boutique_check_period`  | Storefront period                                   | `string`       | `60s`                                              |
| `argocd_check_period`    | Argo period                                         | `string`       | `300s`                                             |
| `check_timeout`          | Timeout                                             | `string`       | `10s`                                              |
| `selected_regions`       | Probe regions                                       | `list(string)` | USA, EUROPE, ASIA_PACIFIC                          |
| `pagerduty_display_name` | Channel display name                                | `string`       | `pagerduty-boutique-production`                    |
| `pagerduty_service_key`  | Events API v2 key (sensitive); empty = skip channel | `string`       | `""`                                               |
| `user_labels`            | Resource labels                                     | `map(string)`  | `managed-by=terraform`, `part-of=boutique-gke-sre` |

## Outputs

| Name                                  | Description                |
| ------------------------------------- | -------------------------- |
| `boutique_uptime_check_id`            | Check ID for alert filters |
| `boutique_uptime_check_name`          | Full resource name         |
| `argocd_uptime_check_id`              | Check ID for alert filters |
| `argocd_uptime_check_name`            | Full resource name         |
| `pagerduty_notification_channel_id`   | Channel ID or `null`       |
| `pagerduty_notification_channel_name` | Channel name or `null`     |

## Dependencies

- `project-apis` — `monitoring.googleapis.com` enabled
- Live HTTPS endpoints (topics 06, 09, 12) before uptime checks stay green
- PagerDuty integration key from Secret Manager / CI secret — **never commit**

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_id            = var.project_id
  pagerduty_service_key = var.pagerduty_service_key # sensitive; from tfvars / GSM
}
```

Environment wiring (topic 19): `enable_monitoring_iac` with `count` in `environments/boutique`.

## Dual path with scripts

| Concern           | Prefer when `enable_monitoring_iac=true` | Prefer when false / legacy                                        |
| ----------------- | ---------------------------------------- | ----------------------------------------------------------------- |
| Uptime checks     | This module                              | `scripts/create-uptime-check.sh`, `create-argocd-uptime-check.sh` |
| PagerDuty channel | This module                              | Topic 14 Console / channel create                                 |
| Burn / SLO alerts | Scripts + reference YAML                 | Same                                                              |

Reference YAML under `observability/monitoring/uptime-checks/` remains documentation of intent; Terraform is the recreate path when IaC is enabled.

## Setup guide

[docs/setup/19-monitoring-backup-terraform.md](../../../docs/setup/19-monitoring-backup-terraform.md) (created in topic 19).

## Implementation phase

**Phase 9-C** — after rebuild topics 12–14; optional alongside topics 17–18.
