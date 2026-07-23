variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "boutique_hostname" {
  description = "Storefront FQDN for HTTPS uptime check."
  type        = string
  default     = "boutique.biroltilki.art"
}

variable "argocd_hostname" {
  description = "Argo CD FQDN for HTTPS uptime check."
  type        = string
  default     = "argocd.boutique.biroltilki.art"
}

variable "argocd_health_path" {
  description = "Path for Argo CD health probe."
  type        = string
  default     = "/healthz"
}

variable "boutique_check_period" {
  description = "Storefront uptime check period (e.g. 60s)."
  type        = string
  default     = "60s"
}

variable "argocd_check_period" {
  description = "Argo CD uptime check period (e.g. 300s)."
  type        = string
  default     = "300s"
}

variable "check_timeout" {
  description = "Per-check timeout."
  type        = string
  default     = "10s"
}

variable "selected_regions" {
  description = "Uptime check regions (GCP Monitoring region identifiers)."
  type        = list(string)
  default = [
    "USA",
    "EUROPE",
    "ASIA_PACIFIC",
  ]
}

variable "pagerduty_display_name" {
  description = "Display name for the PagerDuty notification channel."
  type        = string
  default     = "pagerduty-boutique-production"
}

variable "pagerduty_service_key" {
  description = "PagerDuty Events API v2 integration key. Leave empty to skip channel creation."
  type        = string
  default     = ""
  sensitive   = true
}

variable "user_labels" {
  description = "Labels applied to Monitoring resources."
  type        = map(string)
  default = {
    managed-by = "terraform"
    part-of    = "boutique-gke-sre"
  }
}
