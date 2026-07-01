output "project_id" {
  description = "GCP project ID."
  value       = var.project_id
}

output "region" {
  description = "GCP region."
  value       = var.region
}

# --- Phase 1 (available after topic 03) ---

output "network_name" {
  description = "VPC network name."
  value       = module.networking.network_name
}

output "subnet_name" {
  description = "GKE subnet name."
  value       = module.networking.subnet_name
}

output "pods_range_name" {
  description = "Secondary range name for pod IPs."
  value       = module.networking.pods_range_name
}

output "services_range_name" {
  description = "Secondary range name for service IPs."
  value       = module.networking.services_range_name
}

output "enabled_apis" {
  description = "GCP APIs enabled."
  value       = module.project_apis.enabled_apis
}

# --- Phase 2 (null until gke / ingress_edge / dns modules are applied) ---

output "cluster_name" {
  description = "GKE cluster name (Phase 2)."
  value       = try(module.gke.cluster_name, null)
}

output "cluster_location" {
  description = "GKE cluster region (Phase 2)."
  value       = try(module.gke.cluster_location, null)
}

output "ingress_static_ip" {
  description = "Global static IP for Ingress — use in Kubernetes Ingress annotation (Phase 2)."
  value       = try(module.ingress_edge.address, null)
}

output "dns_name_servers" {
  description = "Cloud DNS name servers — delegate at domain registrar (Phase 2)."
  value       = try(module.dns.name_servers, null)
}

output "boutique_url" {
  description = "Storefront URL."
  value       = "https://${var.boutique_hostname}"
}

output "argocd_url" {
  description = "Argo CD URL."
  value       = "https://${var.argocd_hostname}"
}

# --- Phase 3 (available after topic 07 WIF apply) ---

output "wif_provider_name" {
  description = "GitHub OIDC WIF provider — GitHub secret GCP_WORKLOAD_IDENTITY_PROVIDER."
  value       = try(module.wif.wif_provider_name, null)
}

output "ci_service_account_email" {
  description = "GitHub Actions CI service account email — GitHub secret GCP_SERVICE_ACCOUNT."
  value       = try(module.wif.ci_service_account_email, null)
}
