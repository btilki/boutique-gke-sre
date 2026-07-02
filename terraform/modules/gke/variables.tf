variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for the regional cluster."
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "boutique-gke"
}

variable "network_name" {
  description = "VPC network name."
  type        = string
}

variable "subnet_name" {
  description = "GKE subnet name."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "master_ipv4_cidr" {
  description = "RFC1918 CIDR for GKE control plane private endpoint."
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_pool_name" {
  description = "Primary node pool name."
  type        = string
  default     = "boutique-primary"
}

variable "machine_type" {
  description = "Node machine type."
  type        = string
  default     = "e2-standard-4"
}

variable "min_node_count" {
  description = "Minimum nodes per zone in the pool."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes per zone in the pool."
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "Initial node count per zone."
  type        = number
  default     = 1
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "deletion_protection" {
  description = "Prevent accidental cluster deletion via Terraform."
  type        = bool
  default     = false
}

variable "binary_authorization_evaluation_mode" {
  description = "GKE Binary Authorization evaluation mode. Use PROJECT_SINGLETON_POLICY_ENFORCE when Binary Authorization policy is active."
  type        = string
  default     = "DISABLED"

  validation {
    condition = contains([
      "DISABLED",
      "PROJECT_SINGLETON_POLICY_ENFORCE",
    ], var.binary_authorization_evaluation_mode)
    error_message = "binary_authorization_evaluation_mode must be DISABLED or PROJECT_SINGLETON_POLICY_ENFORCE."
  }
}
