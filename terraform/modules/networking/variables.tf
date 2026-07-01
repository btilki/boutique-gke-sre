variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for subnet and NAT."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "boutique-vpc"
}

variable "subnet_name" {
  description = "Name of the primary GKE subnet."
  type        = string
  default     = "boutique-gke-subnet"
}

variable "subnet_cidr" {
  description = "Primary CIDR for GKE nodes."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR for pod IP alias range."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR for services IP alias range."
  type        = string
  default     = "10.30.0.0/20"
}

variable "pods_range_name" {
  description = "Name of the secondary IP range for pods."
  type        = string
  default     = "boutique-pods"
}

variable "services_range_name" {
  description = "Name of the secondary IP range for services."
  type        = string
  default     = "boutique-services"
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs on the GKE subnet."
  type        = bool
  default     = true
}

variable "router_name" {
  description = "Cloud Router name for NAT."
  type        = string
  default     = "boutique-router"
}

variable "nat_name" {
  description = "Cloud NAT name."
  type        = string
  default     = "boutique-nat"
}
