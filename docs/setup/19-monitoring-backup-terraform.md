# Monitoring + Backup Terraform (IaC)

## Goal

On a rebuilt cluster, enable Terraform modules for **Cloud Monitoring uptime checks** (and optional PagerDuty channel) and a **GKE Backup** plan. When complete, those primitives recreate from `terraform apply` instead of Console/scripts alone.

**Repo status:** Modules and env wiring exist with flags default **`false`**. This guide is the **future apply** path. SLO burn-rate policies remain script/YAML-driven (dual path).

## Why this step is required

Topics 13–14 and scripts create uptime and channels imperatively. After teardown, that knowledge lived in YAML comments. Topic 19 makes uptime + backup **declarative** and teardown-safe (`enable_*_iac` off by default).

## Prerequisites

- Prior guides: topics **02–04** (state + GKE), **06/09/12** (HTTPS edges for green uptime), **14** (PagerDuty key available)
- Recommended after or alongside [17](17-latency-slos-dashboards.md) / [18](18-sre-operability-game-days.md)
- Tools: `terraform` ≥ 1.5, `gcloud`, `curl`
- Access: Terraform SA / user with Monitoring Admin + GKE Backup Admin on `boutique-gke`
- Modules: `terraform/modules/monitoring`, `terraform/modules/backup`
- Env: `terraform/environments/boutique` with `enable_monitoring_iac` / `enable_backup_iac`

## Commands

```bash
cd terraform/environments/boutique
export PROJECT_ID=boutique-gke
```

### 1. Enable monitoring IaC

In `terraform.tfvars` (do **not** commit secrets):

```hcl
enable_monitoring_iac = true
# Prefer env var over tfvars for the key:
# export TF_VAR_pagerduty_service_key='…'
pagerduty_channel_display_name = "pagerduty-boutique-production"
```

```bash
terraform init
terraform plan \
  -target=module.monitoring \
  -out=tfplan-monitoring
terraform apply tfplan-monitoring
terraform output boutique_uptime_check_id
terraform output argocd_uptime_check_id
```

If the PagerDuty channel was created:

```bash
./scripts/attach-pagerduty-channel.sh
```

**Dual path:** With IaC on, skip `create-uptime-check.sh` / `create-argocd-uptime-check.sh` for the same hosts (avoid duplicate checks). Still use burn-rate scripts for SLOs:

```bash
./scripts/create-burn-rate-policies.sh
./scripts/create-latency-burn-rate-policies.sh   # after topic 17 SLOs
./scripts/create-supplemental-alert-policies.sh
```

Wire `uptime-check-failed` OR conditions to both check IDs (see [uptime-check-failed.yaml](../../observability/monitoring/alert-policies/uptime-check-failed.yaml)).

### 2. Enable backup IaC

```hcl
enable_backup_iac    = true
backup_plan_name     = "boutique-daily"
backup_retain_days   = 7
backup_cron_schedule = "0 3 * * *"
backup_deactivated   = false
```

```bash
terraform plan \
  -target=module.backup \
  -out=tfplan-backup
terraform apply tfplan-backup
terraform output backup_plan_id
terraform output backup_plan_name
```

### 3. Optional full plan (both flags true)

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Expected output

- Uptime configs: `boutique-storefront`, `argocd-ui`
- Optional channel: `pagerduty-boutique-production` (or configured name)
- Backup plan: `boutique-daily` covering `boutique`, `argocd`, `observability`
- Terraform outputs non-null for enabled modules

## Validation

**Repo (always):**

```bash
cd terraform/environments/boutique
terraform init -backend=false
terraform validate
```

**Live (after apply):**

```bash
gcloud monitoring uptime list-configs --project=boutique-gke \
  --format='table(displayName,httpCheck.path,period)'
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art/healthz

gcloud container backup-restore backup-plans list \
  --project=boutique-gke --location=europe-west1
```

Restore drill (scheduled): follow [redis-restore.md](../sre/runbooks/redis-restore.md) / [cluster-rebuild.md](../sre/runbooks/cluster-rebuild.md) using the plan from `terraform output backup_plan_name`.

## Common problems

| Symptom                                | Cause                         | Fix                                                                                  |
| -------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------ |
| Duplicate uptime checks                | Scripts + TF both used        | Delete script-created duplicates; keep TF                                            |
| Uptime red                             | HTTPS/DNS not ready           | Finish topics 06/09/12 first                                                         |
| No PagerDuty channel                   | Empty `pagerduty_service_key` | Set `TF_VAR_pagerduty_service_key`                                                   |
| Backup plan create fails               | API / cluster ID              | Confirm `gkebackup.googleapis.com`; cluster exists                                   |
| `terraform destroy` blocked by backups | Retention / lock              | Set `backup_deactivated=true`; delete old backups; see [teardown.md](../teardown.md) |

## Recovery

- Disable modules: set `enable_*_iac = false` → plan → apply (destroys TF-managed resources)
- Re-create from scripts if rolling back IaC (topics 13–14 / 18)
- Emergency: Console delete uptime check or backup plan; re-import or re-apply

## Best practices

- Keep flags **false** until HTTPS and GKE exist
- Never commit `pagerduty_service_key`
- Prefer `-target` on first enable to limit blast radius
- Document which path owns uptime (TF vs scripts) in the change log after rebuild
- Before teardown: `backup_deactivated = true` and purge costly snapshots

## Security notes

- PagerDuty key is sensitive — Secret Manager / `TF_VAR_*` only
- Backup includes Secrets (`include_secrets=true`) — restrict who can restore
- Uptime probes must not embed credentials
- Least privilege: Monitoring Editor + Backup Admin for operators, not Owner

## Next step

| Step                     | Guide                                                                  |
| ------------------------ | ---------------------------------------------------------------------- |
| Latency SLOs             | [17-latency-slos-dashboards.md](17-latency-slos-dashboards.md)         |
| Operability / game days  | [18-sre-operability-game-days.md](18-sre-operability-game-days.md)     |
| Teardown                 | [teardown.md](../teardown.md)                                          |
| SRE practices (topic 20) | [20-sre-practices-capacity-toil.md](20-sre-practices-capacity-toil.md) |
| Optional C2              | SLO burn in Terraform — [ROADMAP.md](../../ROADMAP.md)                 |
