variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "address_name" {
  description = "Name of the global static IP address."
  type        = string
  default     = "boutique-ingress-ip"
}

variable "description" {
  description = "Description for the static IP resource."
  type        = string
  default     = "Global static IP for boutique + argocd ingress"
}
