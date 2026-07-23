output "boutique_uptime_check_id" {
  description = "Uptime check ID for boutique-storefront (last path segment of name)."
  value       = element(split("/", google_monitoring_uptime_check_config.boutique_storefront.id), length(split("/", google_monitoring_uptime_check_config.boutique_storefront.id)) - 1)
}

output "boutique_uptime_check_name" {
  description = "Full resource name of the boutique-storefront uptime check."
  value       = google_monitoring_uptime_check_config.boutique_storefront.name
}

output "argocd_uptime_check_id" {
  description = "Uptime check ID for argocd-ui."
  value       = element(split("/", google_monitoring_uptime_check_config.argocd_ui.id), length(split("/", google_monitoring_uptime_check_config.argocd_ui.id)) - 1)
}

output "argocd_uptime_check_name" {
  description = "Full resource name of the argocd-ui uptime check."
  value       = google_monitoring_uptime_check_config.argocd_ui.name
}

output "pagerduty_notification_channel_id" {
  description = "PagerDuty notification channel ID, or null if pagerduty_service_key was empty."
  value       = local.create_pagerduty ? google_monitoring_notification_channel.pagerduty[0].id : null
  sensitive   = true
}

output "pagerduty_notification_channel_name" {
  description = "PagerDuty notification channel name, or null if not created."
  value       = local.create_pagerduty ? google_monitoring_notification_channel.pagerduty[0].name : null
  sensitive   = true
}
