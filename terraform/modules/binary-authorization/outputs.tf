output "attestor_name" {
  description = "Binary Authorization attestor resource name."
  value       = google_binary_authorization_attestor.cosign.name
}

output "attestor_id" {
  description = "Attestor ID (boutique-cosign-attestor)."
  value       = google_binary_authorization_attestor.cosign.name
}

output "cluster_admission_id" {
  description = "Cluster specifier used in admission policy (location.cluster_name)."
  value       = local.cluster_admission_id
}

output "enforcement_mode" {
  description = "Current cluster admission enforcement mode."
  value       = var.enforcement_mode
}
