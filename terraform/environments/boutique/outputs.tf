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
  description = "Storefront global static IP (boutique-ingress-ip) — Phase 2."
  value       = try(module.ingress_edge.address, null)
}

output "ingress_static_ip_name" {
  description = "Storefront global address resource name (Ingress annotation)."
  value       = try(module.ingress_edge.address_name, null)
}

output "argocd_ingress_static_ip" {
  description = "Argo CD global static IP (argocd-ingress-ip) — Phase 2."
  value       = try(module.ingress_edge.argocd_address, null)
}

output "argocd_ingress_static_ip_name" {
  description = "Argo CD global address resource name (Ingress annotation)."
  value       = try(module.ingress_edge.argocd_address_name, null)
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

output "artifact_registry_repository" {
  description = "Artifact Registry Docker repository path (Phase 3)."
  value       = try(module.artifact_registry.repository_url, null)
}

output "binary_authorization_attestor" {
  description = "Binary Authorization cosign attestor name (Phase 3)."
  value       = try(module.binary_authorization[0].attestor_name, null)
}

output "binary_authorization_enforcement_mode" {
  description = "Binary Authorization cluster enforcement mode (Phase 3)."
  value       = try(module.binary_authorization[0].enforcement_mode, null)
}

output "argocd_armor_policy_name" {
  description = "Cloud Armor policy for Argo CD edge — attach with scripts/attach-argocd-armor.sh."
  value       = try(module.armor_argocd[0].policy_name, null)
}

# --- Phase 9-C (null when enable_*_iac is false) ---

output "boutique_uptime_check_id" {
  description = "Cloud Monitoring uptime check ID for the storefront (when enable_monitoring_iac)."
  value       = try(module.monitoring[0].boutique_uptime_check_id, null)
}

output "argocd_uptime_check_id" {
  description = "Cloud Monitoring uptime check ID for Argo CD (when enable_monitoring_iac)."
  value       = try(module.monitoring[0].argocd_uptime_check_id, null)
}

output "pagerduty_notification_channel_name" {
  description = "PagerDuty notification channel name (when enable_monitoring_iac and key set)."
  value       = try(module.monitoring[0].pagerduty_notification_channel_name, null)
  sensitive   = true
}

output "backup_plan_id" {
  description = "GKE Backup plan ID (when enable_backup_iac)."
  value       = try(module.backup[0].backup_plan_id, null)
}

output "backup_plan_name" {
  description = "GKE Backup plan name (when enable_backup_iac)."
  value       = try(module.backup[0].backup_plan_name, null)
}
