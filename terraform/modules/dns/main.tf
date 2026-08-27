# Cloud DNS zone and A records for boutique + argocd hostnames.

resource "google_dns_managed_zone" "primary" {
  project     = var.project_id
  name        = var.managed_zone_name
  dns_name    = "${var.domain}."
  description = "boutique-gke-sre DNS zone for ${var.domain}"
}

resource "google_dns_record_set" "boutique" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.primary.name
  name         = "${var.boutique_hostname}."
  type         = "A"
  ttl          = var.ttl
  rrdatas      = [var.boutique_ip_address]
}

resource "google_dns_record_set" "argocd" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.primary.name
  name         = "${var.argocd_hostname}."
  type         = "A"
  ttl          = var.ttl
  rrdatas      = [var.argocd_ip_address]
}
