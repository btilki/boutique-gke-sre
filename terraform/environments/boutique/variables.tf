variable "project_id" {
  description = "GCP project ID."
  type        = string
  default     = "boutique-gke"
}

variable "region" {
  description = "Primary GCP region for resources."
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Environment label used in resource naming."
  type        = string
  default     = "boutique"
}

variable "domain" {
  description = "Root DNS domain."
  type        = string
  default     = "biroltilki.art"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "boutique-gke"
}

variable "boutique_hostname" {
  description = "Online Boutique storefront FQDN."
  type        = string
  default     = "boutique.biroltilki.art"
}

variable "argocd_hostname" {
  description = "Argo CD UI FQDN."
  type        = string
  default     = "argocd.boutique.biroltilki.art"
}

variable "deletion_protection" {
  description = "Enable GKE deletion protection."
  type        = bool
  default     = false
}

variable "github_org" {
  description = "GitHub organization or username that owns boutique-gke-sre (WIF trust scope)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name trusted by WIF."
  type        = string
  default     = "boutique-gke-sre"
}

variable "cosign_public_key_pem" {
  description = "Cosign public key PEM for Binary Authorization attestor (from cosign generate-key-pair). Set in terraform.tfvars only."
  type        = string
  default     = ""
}

variable "binary_authorization_enforcement_mode" {
  description = "Binary Authorization cluster enforcement: DRYRUN_AUDIT_LOG_ONLY during bootstrap; ENFORCED_BLOCK_AND_AUDIT_LOG before topic 12."
  type        = string
  default     = "DRYRUN_AUDIT_LOG_ONLY"
}
