# GitHub Actions → GCP via Workload Identity Federation (no JSON keys).

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account" "ci" {
  project      = var.project_id
  account_id   = var.ci_service_account_id
  display_name = "GitHub Actions CI"
  description  = "CI pipeline for ${var.github_org}/${var.github_repo} authenticated via WIF"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC pool for ${var.github_org}/${var.github_repo}"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"
  description                        = "Trust token.actions.githubusercontent.com"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = var.github_ref != null ? "attribute.repository == \"${var.github_org}/${var.github_repo}\" && attribute.ref == \"${var.github_ref}\"" : "attribute.repository == \"${var.github_org}/${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  github_repository_principal = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

resource "google_service_account_iam_member" "ci_wif_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.github_repository_principal
}
