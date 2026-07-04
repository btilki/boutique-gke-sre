# Cloud Armor backend security policy — rate limiting, optional IP allowlist, OWASP CRS.

locals {
  description = var.description != "" ? var.description : "Edge WAF policy ${var.policy_name}"
}

resource "google_compute_security_policy" "this" {
  project     = var.project_id
  name        = var.policy_name
  description = local.description
  type        = "CLOUD_ARMOR"

  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = var.log_level
  }

  # Optional admin IP allowlist — evaluated first (lowest priority number).
  dynamic "rule" {
    for_each = length(var.allowed_source_cidrs) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = 500
      description = "Allow admin source CIDRs"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.allowed_source_cidrs
        }
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.allowed_source_cidrs) > 0 ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 501
      description = "Deny all sources not in admin allowlist"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }
    }
  }

  # OWASP CRS — must evaluate before rate limit (first match wins; rate limit allow would skip CRS).
  dynamic "rule" {
    for_each = var.enable_owasp_crs ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 1000
      description = "OWASP CRS - SQLi"
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('sqli-stable')"
        }
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_crs ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 1001
      description = "OWASP CRS - XSS"
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('xss-stable')"
        }
      }
    }
  }

  rule {
    action      = "rate_based_ban"
    priority    = 2000
    description = "Rate limit brute-force and scan traffic"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = var.rate_limit_count
        interval_sec = var.rate_limit_interval_sec
      }
      ban_duration_sec = var.rate_limit_ban_duration_sec
    }
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
