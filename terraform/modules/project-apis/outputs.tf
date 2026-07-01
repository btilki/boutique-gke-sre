output "enabled_apis" {
  description = "Set of API service names enabled."
  value       = sort([for api in google_project_service.apis : api.service])
}
