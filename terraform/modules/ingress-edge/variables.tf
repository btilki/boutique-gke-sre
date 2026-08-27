variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "address_name" {
  description = "Name of the storefront global static IP address."
  type        = string
  default     = "boutique-ingress-ip"
}

variable "description" {
  description = "Description for the storefront static IP resource."
  type        = string
  default     = "Global static IP for boutique.biroltilki.art GCE Ingress"
}

variable "argocd_address_name" {
  description = "Name of the Argo CD global static IP address."
  type        = string
  default     = "argocd-ingress-ip"
}

variable "argocd_description" {
  description = "Description for the Argo CD static IP resource."
  type        = string
  default     = "Global static IP for argocd.boutique.biroltilki.art GCE Ingress"
}
