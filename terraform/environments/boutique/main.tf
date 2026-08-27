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

  project_id          = var.project_id
  domain              = var.domain
  boutique_ip_address = module.ingress_edge.address
  argocd_ip_address   = module.ingress_edge.argocd_address
  boutique_hostname   = var.boutique_hostname
  argocd_hostname     = var.argocd_hostname

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

# Argo CD edge WAF — attach to GKE ingress backend via scripts/attach-argocd-armor.sh
module "armor_argocd" {
  count  = var.enable_argocd_armor ? 1 : 0
  source = "../../modules/armor"

  project_id              = var.project_id
  policy_name             = "argocd-edge"
  description             = "Rate limit + OWASP CRS for argocd.boutique.biroltilki.art"
  allowed_source_cidrs    = var.argocd_armor_allowed_cidrs
  rate_limit_count        = 30
  rate_limit_interval_sec = 60

  depends_on = [time_sleep.wait_for_apis]
}

# Phase 9-C — optional IaC for uptime + PagerDuty channel (default off while torn down)
module "monitoring" {
  count  = var.enable_monitoring_iac ? 1 : 0
  source = "../../modules/monitoring"

  project_id             = var.project_id
  boutique_hostname      = var.boutique_hostname
  argocd_hostname        = var.argocd_hostname
  pagerduty_display_name = var.pagerduty_channel_display_name
  pagerduty_service_key  = var.pagerduty_service_key

  depends_on = [module.project_apis, module.dns, module.gke]
}

# Phase 9-C — optional GKE Backup plan (default off while torn down)
module "backup" {
  count  = var.enable_backup_iac ? 1 : 0
  source = "../../modules/backup"

  project_id         = var.project_id
  location           = var.region
  cluster_id         = "projects/${var.project_id}/locations/${module.gke.cluster_location}/clusters/${module.gke.cluster_name}"
  backup_plan_name   = var.backup_plan_name
  include_namespaces = var.backup_include_namespaces
  backup_retain_days = var.backup_retain_days
  cron_schedule      = var.backup_cron_schedule
  deactivated        = var.backup_deactivated

  depends_on = [module.project_apis, module.gke]
}
