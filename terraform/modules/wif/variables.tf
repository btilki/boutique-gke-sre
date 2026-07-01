variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name trusted by the WIF provider."
  type        = string
  default     = "boutique-gke-sre"
}

variable "pool_id" {
  description = "Workload Identity pool ID."
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload Identity pool provider ID."
  type        = string
  default     = "github-provider"
}

variable "ci_service_account_id" {
  description = "Service account ID (without domain) for GitHub Actions CI."
  type        = string
  default     = "github-ci"
}

variable "github_ref" {
  description = "Optional Git ref attribute condition (e.g. refs/heads/main). Null trusts all refs from the repository."
  type        = string
  default     = null
}
