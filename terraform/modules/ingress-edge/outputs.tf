output "address_name" {
  description = "Static global address resource name."
  value       = google_compute_global_address.ingress.name
}

output "address" {
  description = "Reserved global IPv4 address for Ingress annotations."
  value       = google_compute_global_address.ingress.address
}
