variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "policy_name" {
  description = "Cloud Armor security policy resource name."
  type        = string
}

variable "description" {
  description = "Human-readable policy description."
  type        = string
  default     = ""
}

variable "allowed_source_cidrs" {
  description = "Optional source CIDR allowlist. When non-empty, all other sources are denied before WAF rules."
  type        = list(string)
  default     = []
}

variable "rate_limit_count" {
  description = "Max requests per IP per interval before rate-based ban."
  type        = number
  default     = 60
}

variable "rate_limit_interval_sec" {
  description = "Rate limit evaluation window in seconds."
  type        = number
  default     = 60
}

variable "rate_limit_ban_duration_sec" {
  description = "Ban duration in seconds after rate limit exceeded."
  type        = number
  default     = 300
}

variable "enable_owasp_crs" {
  description = "Enable OWASP CRS preconfigured expressions (SQLi, XSS)."
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Cloud Armor request log level: NORMAL or VERBOSE."
  type        = string
  default     = "NORMAL"

  validation {
    condition     = contains(["NORMAL", "VERBOSE"], var.log_level)
    error_message = "log_level must be NORMAL or VERBOSE."
  }
}
