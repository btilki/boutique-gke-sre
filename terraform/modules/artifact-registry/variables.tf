variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "Regional location for the Docker repository."
  type        = string
  default     = "europe-west1"
}

variable "repository_id" {
  description = "Artifact Registry repository ID."
  type        = string
  default     = "boutique"
}

variable "description" {
  description = "Human-readable repository description."
  type        = string
  default     = "Online Boutique images — digest-only promotion"
}

variable "ci_service_account_email" {
  description = "GitHub Actions CI service account — granted artifactregistry.writer."
  type        = string
}

variable "grant_node_pull" {
  description = "Grant artifactregistry.reader to the default Compute Engine service account (GKE node pulls)."
  type        = bool
  default     = true
}
