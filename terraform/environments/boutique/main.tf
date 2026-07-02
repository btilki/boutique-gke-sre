# Phase 1: APIs + networking
# Phase 2: GKE + static IP + DNS
# Phase 3: GitHub WIF + Artifact Registry + Binary Authorization

locals {
  binary_authorization_enabled = var.cosign_public_key_pem != ""
}

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

  project_id                           = var.project_id
  region                               = var.region
  cluster_name                         = var.cluster_name
  network_name                         = module.networking.network_name
  subnet_name                          = module.networking.subnet_name
  pods_range_name                      = module.networking.pods_range_name
  services_range_name                  = module.networking.services_range_name
  deletion_protection                  = var.deletion_protection
  binary_authorization_evaluation_mode = local.binary_authorization_enabled ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"

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

module "wif" {
  source = "../../modules/wif"

  project_id  = var.project_id
  github_org  = var.github_org
  github_repo = var.github_repo

  depends_on = [time_sleep.wait_for_apis]
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id               = var.project_id
  location                 = var.region
  repository_id            = "boutique"
  description              = "Online Boutique images — digest-only promotion"
  ci_service_account_email = module.wif.ci_service_account_email

  depends_on = [module.project_apis, module.wif]
}

module "binary_authorization" {
  count  = local.binary_authorization_enabled ? 1 : 0
  source = "../../modules/binary-authorization"

  project_id                 = var.project_id
  cluster_name               = var.cluster_name
  location                   = var.region
  cosign_public_key_pem      = var.cosign_public_key_pem
  enforcement_mode           = var.binary_authorization_enforcement_mode
  cosign_signature_algorithm = "ECDSA_P256_SHA256"

  depends_on = [module.project_apis, module.gke]
}
