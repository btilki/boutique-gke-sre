output "wif_provider_name" {
  description = "Full resource name of the GitHub OIDC WIF provider — use as GCP_WORKLOAD_IDENTITY_PROVIDER in GitHub Secrets."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "ci_service_account_email" {
  description = "CI service account email — use as GCP_SERVICE_ACCOUNT in GitHub Secrets."
  value       = google_service_account.ci.email
}

output "workload_identity_pool_name" {
  description = "Full resource name of the Workload Identity pool."
  value       = google_iam_workload_identity_pool.github.name
}

output "github_principal_set" {
  description = "Principal set allowed to impersonate the CI service account."
  value       = local.github_repository_principal
}
