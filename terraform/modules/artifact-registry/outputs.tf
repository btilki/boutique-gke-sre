output "repository_id" {
  description = "Artifact Registry repository ID."
  value       = google_artifact_registry_repository.boutique.repository_id
}

output "location" {
  description = "Regional location of the repository."
  value       = google_artifact_registry_repository.boutique.location
}

output "repository_name" {
  description = "Full resource name (projects/.../repositories/boutique)."
  value       = google_artifact_registry_repository.boutique.name
}

output "repository_url" {
  description = "Docker repository path for image references (location-docker.pkg.dev/project/repo)."
  value       = "${google_artifact_registry_repository.boutique.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.boutique.repository_id}"
}
