output "backup_plan_id" {
  description = "Full resource ID of the GKE Backup plan."
  value       = google_gke_backup_backup_plan.this.id
}

output "backup_plan_name" {
  description = "Backup plan name."
  value       = google_gke_backup_backup_plan.this.name
}

output "backup_plan_location" {
  description = "Location of the backup plan."
  value       = google_gke_backup_backup_plan.this.location
}

output "backup_plan_uid" {
  description = "UID of the backup plan."
  value       = google_gke_backup_backup_plan.this.uid
}

output "include_namespaces" {
  description = "Namespaces covered by the plan."
  value       = var.include_namespaces
}
