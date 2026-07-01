output "network_id" {
  description = "VPC network self link."
  value       = google_compute_network.vpc.self_link
}

output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "GKE subnet self link."
  value       = google_compute_subnetwork.gke.self_link
}

output "subnet_name" {
  description = "GKE subnet name."
  value       = google_compute_subnetwork.gke.name
}

output "pods_range_name" {
  description = "Secondary range name for pod IPs."
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Secondary range name for service IPs."
  value       = var.services_range_name
}

output "router_name" {
  description = "Cloud Router name."
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Cloud NAT name."
  value       = google_compute_router_nat.nat.name
}
