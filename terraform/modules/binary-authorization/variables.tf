variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name for cluster-specific admission rule."
  type        = string
}

variable "location" {
  description = "Regional location of the GKE cluster (e.g. europe-west1)."
  type        = string
  default     = "europe-west1"
}

variable "attestor_id" {
  description = "Binary Authorization attestor resource ID."
  type        = string
  default     = "boutique-cosign-attestor"
}

variable "attestor_description" {
  description = "Human-readable attestor description."
  type        = string
  default     = "Trust cosign signatures from CI pipeline"
}

variable "cosign_public_key_pem" {
  description = "Cosign public key PEM (from cosign generate-key-pair). Stored in terraform.tfvars — never commit cosign.key."
  type        = string
}

variable "cosign_signature_algorithm" {
  description = "PKIX signature algorithm matching the cosign key pair (default cosign uses ECDSA P-256)."
  type        = string
  default     = "ECDSA_P256_SHA256"
}

variable "enforcement_mode" {
  description = "Cluster admission enforcement: DRYRUN_AUDIT_LOG_ONLY during bootstrap; ENFORCED_BLOCK_AND_AUDIT_LOG after signed images are validated."
  type        = string
  default     = "DRYRUN_AUDIT_LOG_ONLY"

  validation {
    condition     = contains(["DRYRUN_AUDIT_LOG_ONLY", "ENFORCED_BLOCK_AND_AUDIT_LOG"], var.enforcement_mode)
    error_message = "enforcement_mode must be DRYRUN_AUDIT_LOG_ONLY or ENFORCED_BLOCK_AND_AUDIT_LOG."
  }
}

variable "platform_image_whitelist_patterns" {
  description = "Image name patterns exempt from cosign attestation (platform controllers not mirrored to AR with attestations)."
  type        = list(string)
  default = [
    "quay.io/argoproj/*",
    "ghcr.io/kyverno/*",
    "ghcr.io/external-secrets/*",
    "docker.io/redis*",
    "docker.io/bitnami/*",
    "registry.k8s.io/*",
  ]
}
