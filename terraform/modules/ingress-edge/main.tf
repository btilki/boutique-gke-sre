# Global static IP reserved for GCE Ingress (boutique + argocd hostnames).

resource "google_compute_global_address" "ingress" {
  project      = var.project_id
  name         = var.address_name
  description  = var.description
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
