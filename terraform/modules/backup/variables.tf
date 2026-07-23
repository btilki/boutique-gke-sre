variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "Region for the GKE Backup plan (typically same as the cluster region)."
  type        = string
}

variable "cluster_id" {
  description = "Full cluster resource ID: projects/PROJECT/locations/LOCATION/clusters/NAME."
  type        = string
}

variable "backup_plan_name" {
  description = "GKE Backup plan resource name."
  type        = string
  default     = "boutique-daily"
}

variable "include_namespaces" {
  description = "Namespaces included in each backup."
  type        = list(string)
  default     = ["boutique", "argocd", "observability"]
}

variable "include_volume_data" {
  description = "Include PersistentVolume data in backups."
  type        = bool
  default     = true
}

variable "include_secrets" {
  description = "Include Secret resources in backups (ESO-synced secrets)."
  type        = bool
  default     = true
}

variable "backup_retain_days" {
  description = "Automatic deletion age for backups (days). Must be >= backup_delete_lock_days."
  type        = number
  default     = 7
}

variable "backup_delete_lock_days" {
  description = "Minimum days before a backup can be deleted."
  type        = number
  default     = 1
}

variable "cron_schedule" {
  description = "Cron schedule for automated backups (UTC)."
  type        = string
  default     = "0 3 * * *" # daily 03:00 UTC
}

variable "deactivated" {
  description = "If true, the plan does not create new backups (useful during teardown)."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to the backup plan."
  type        = map(string)
  default = {
    managed-by = "terraform"
    part-of    = "boutique-gke-sre"
  }
}
