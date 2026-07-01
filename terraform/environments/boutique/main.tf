# Phase 1: APIs + networking
# Phase 2: GKE + static IP + DNS

module "project_apis" {
  source = "../../modules/project-apis"

  project_id = var.project_id
}

# GCP API enablement can lag behind Terraform apply; avoid flaky networking creates.
resource "time_sleep" "wait_for_apis" {
  depends_on = [module.project_apis]

  create_duration = "60s"
}

module "networking" {
  source = "../../modules/networking"

  project_id = var.project_id
  region     = var.region

  depends_on = [time_sleep.wait_for_apis]
}

module "ingress_edge" {
  source = "../../modules/ingress-edge"

  project_id = var.project_id

  depends_on = [time_sleep.wait_for_apis]
}

module "gke" {
  source = "../../modules/gke"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  network_name        = module.networking.network_name
  subnet_name         = module.networking.subnet_name
  pods_range_name     = module.networking.pods_range_name
  services_range_name = module.networking.services_range_name
  deletion_protection = var.deletion_protection

  depends_on = [module.networking]
}

module "dns" {
  source = "../../modules/dns"

  project_id        = var.project_id
  domain            = var.domain
  static_ip_address = module.ingress_edge.address
  boutique_hostname = var.boutique_hostname
  argocd_hostname   = var.argocd_hostname

  depends_on = [module.ingress_edge]
}
