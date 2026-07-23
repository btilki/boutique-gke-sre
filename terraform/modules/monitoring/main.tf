# Cloud Monitoring primitives for boutique-gke-sre (Phase 9-C).
# Owns HTTPS uptime checks + optional PagerDuty notification channel.
# SLO definitions and multi-window burn-rate alert policies remain script/YAML-driven
# (observability/ + scripts/create-*-burn-rate-policies.sh) until a future C2 migration.

locals {
  create_pagerduty = var.pagerduty_service_key != ""
}

resource "google_monitoring_uptime_check_config" "boutique_storefront" {
  project      = var.project_id
  display_name = "boutique-storefront"
  timeout      = var.check_timeout
  period       = var.boutique_check_period

  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.boutique_hostname
    }
  }

  selected_regions = var.selected_regions

  user_labels = merge(var.user_labels, {
    target = "boutique-storefront"
  })
}

resource "google_monitoring_uptime_check_config" "argocd_ui" {
  project      = var.project_id
  display_name = "argocd-ui"
  timeout      = var.check_timeout
  period       = var.argocd_check_period

  http_check {
    path         = var.argocd_health_path
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.argocd_hostname
    }
  }

  selected_regions = var.selected_regions

  user_labels = merge(var.user_labels, {
    target = "argocd-ui"
  })
}

resource "google_monitoring_notification_channel" "pagerduty" {
  count = local.create_pagerduty ? 1 : 0

  project      = var.project_id
  display_name = var.pagerduty_display_name
  type         = "pagerduty"
  enabled      = true

  labels = {
    service_key = var.pagerduty_service_key
  }

  user_labels = var.user_labels
}
