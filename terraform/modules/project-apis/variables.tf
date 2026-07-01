variable "project_id" {
  description = "GCP project ID where APIs will be enabled."
  type        = string
}

variable "apis" {
  description = "Google Cloud API service names to enable (serviceusage.googleapis.com form)."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "binaryauthorization.googleapis.com",
    "gkebackup.googleapis.com",
    # Cloud Armor is managed via compute.googleapis.com (no separate API)
    "certificatemanager.googleapis.com",
  ]
}

variable "disable_on_destroy" {
  description = "Whether to disable APIs when the module is destroyed. Keep false for production safety."
  type        = bool
  default     = false
}
