output "address_name" {
  description = "Storefront static global address resource name (Ingress annotation)."
  value       = google_compute_global_address.ingress.name
}

output "address" {
  description = "Reserved global IPv4 address for the storefront Ingress."
  value       = google_compute_global_address.ingress.address
}

output "argocd_address_name" {
  description = "Argo CD static global address resource name (Ingress annotation)."
  value       = google_compute_global_address.argocd.name
}

output "argocd_address" {
  description = "Reserved global IPv4 address for the Argo CD Ingress."
  value       = google_compute_global_address.argocd.address
}
