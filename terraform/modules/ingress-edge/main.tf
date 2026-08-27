# Two global static IPs — one GCE Ingress per hostname (Boutique + Argo CD).

resource "google_compute_global_address" "ingress" {
  project      = var.project_id
  name         = var.address_name
  description  = var.description
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_global_address" "argocd" {
  project      = var.project_id
  name         = var.argocd_address_name
  description  = var.argocd_description
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
