# Regional Docker Artifact Registry for digest-only image promotion.

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository" "boutique" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  # Delete untagged manifests older than 30 days (cost control).
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "delete-untagged-older-than-30d"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s"
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "ci_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.boutique.location
  repository = google_artifact_registry_repository.boutique.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_artifact_registry_repository_iam_member" "node_reader" {
  count = var.grant_node_pull ? 1 : 0

  project    = var.project_id
  location   = google_artifact_registry_repository.boutique.location
  repository = google_artifact_registry_repository.boutique.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}
