variable "project_id" {
  description = "GCP project ID."
  type        = string
  default     = "boutique-gke"
}

variable "region" {
  description = "Primary GCP region for resources."
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Environment label used in resource naming."
  type        = string
  default     = "boutique"
}

variable "domain" {
  description = "Root DNS domain."
  type        = string
  default     = "biroltilki.art"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "boutique-gke"
}

variable "boutique_hostname" {
  description = "Online Boutique storefront FQDN."
  type        = string
  default     = "boutique.biroltilki.art"
}

variable "argocd_hostname" {
  description = "Argo CD UI FQDN."
  type        = string
  default     = "argocd.boutique.biroltilki.art"
}

variable "deletion_protection" {
  description = "Enable GKE deletion protection."
  type        = bool
  default     = false
}

variable "github_org" {
  description = "GitHub organization or username that owns boutique-gke-sre (WIF trust scope)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name trusted by WIF."
  type        = string
  default     = "boutique-gke-sre"
}

variable "cosign_public_key_pem" {
  description = "Cosign public key PEM for Binary Authorization attestor (from cosign generate-key-pair). Set in terraform.tfvars only."
  type        = string
  default     = ""
}

variable "binary_authorization_enforcement_mode" {
  description = "Binary Authorization cluster enforcement: DRYRUN_AUDIT_LOG_ONLY during bootstrap; ENFORCED_BLOCK_AND_AUDIT_LOG after smoke validation."
  type        = string
  default     = "DRYRUN_AUDIT_LOG_ONLY"
}

variable "argocd_armor_allowed_cidrs" {
  description = "Optional source CIDRs allowed to reach Argo CD (e.g. office/VPN). Empty = public with rate limit + WAF only."
  type        = list(string)
  default     = []
}

variable "enable_argocd_armor" {
  description = "Create Cloud Armor policy argocd-edge for the Argo CD ingress backend."
  type        = bool
  default     = true
}

# --- Phase 9-C (default false — safe with decommissioned project) ---

variable "enable_monitoring_iac" {
  description = "Provision Cloud Monitoring uptime checks (+ optional PagerDuty channel) via terraform/modules/monitoring."
  type        = bool
  default     = false
}

variable "pagerduty_service_key" {
  description = "PagerDuty Events API v2 integration key for the Monitoring notification channel. Empty skips channel creation. Never commit the real value."
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_channel_display_name" {
  description = "Display name for the PagerDuty notification channel."
  type        = string
  default     = "pagerduty-boutique-production"
}

variable "enable_backup_iac" {
  description = "Provision GKE Backup plan via terraform/modules/backup."
  type        = bool
  default     = false
}

variable "backup_plan_name" {
  description = "GKE Backup plan name when enable_backup_iac is true."
  type        = string
  default     = "boutique-daily"
}

variable "backup_include_namespaces" {
  description = "Namespaces included in the GKE Backup plan."
  type        = list(string)
  default     = ["boutique", "argocd", "observability"]
}

variable "backup_retain_days" {
  description = "Backup retention in days."
  type        = number
  default     = 7
}

variable "backup_cron_schedule" {
  description = "Cron schedule for automated backups (UTC)."
  type        = string
  default     = "0 3 * * *"
}

variable "backup_deactivated" {
  description = "Pause new backups (set true before teardown if needed)."
  type        = bool
  default     = false
}
