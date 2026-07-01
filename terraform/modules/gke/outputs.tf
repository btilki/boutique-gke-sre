output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.primary.name
}

output "cluster_location" {
  description = "Regional location of the cluster."
  value       = google_container_cluster.primary.location
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool for Kubernetes SA bindings."
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}
