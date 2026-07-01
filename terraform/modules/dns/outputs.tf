output "managed_zone_name" {
  description = "Cloud DNS managed zone name."
  value       = google_dns_managed_zone.primary.name
}

output "name_servers" {
  description = "Delegate these NS records at your domain registrar."
  value       = google_dns_managed_zone.primary.name_servers
}

output "boutique_fqdn" {
  description = "Storefront FQDN."
  value       = var.boutique_hostname
}

output "argocd_fqdn" {
  description = "Argo CD FQDN."
  value       = var.argocd_hostname
}
