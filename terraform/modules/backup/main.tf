# GKE Backup plan for boutique-gke-sre (Phase 9-C).
# Supports restore drills documented in docs/sre/runbooks/ and docs/teardown.md.
# Requires gkebackup.googleapis.com (project-apis module).

resource "google_gke_backup_backup_plan" "this" {
  project     = var.project_id
  name        = var.backup_plan_name
  location    = var.location
  cluster     = var.cluster_id
  deactivated = var.deactivated
  labels      = var.labels

  retention_policy {
    backup_retain_days      = var.backup_retain_days
    backup_delete_lock_days = var.backup_delete_lock_days
  }

  backup_schedule {
    cron_schedule = var.cron_schedule
  }

  backup_config {
    include_volume_data = var.include_volume_data
    include_secrets     = var.include_secrets

    selected_namespaces {
      namespaces = var.include_namespaces
    }
  }
}
