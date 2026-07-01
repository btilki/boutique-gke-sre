variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "domain" {
  description = "Root DNS domain (e.g. biroltilki.art)."
  type        = string
}

variable "static_ip_address" {
  description = "Global static IP address for boutique and argocd hostnames."
  type        = string
}

variable "managed_zone_name" {
  description = "Cloud DNS managed zone resource name."
  type        = string
  default     = "biroltilki-art"
}

variable "boutique_hostname" {
  description = "Storefront FQDN."
  type        = string
  default     = "boutique.biroltilki.art"
}

variable "argocd_hostname" {
  description = "Argo CD FQDN."
  type        = string
  default     = "argocd.boutique.biroltilki.art"
}

variable "ttl" {
  description = "TTL for A records in seconds."
  type        = number
  default     = 300
}
