output "api_url" {
  description = "Backend API base URL"
  value       = "https://${azurerm_linux_web_app.api.default_hostname}"
}

output "frontend_url" {
  description = "Static Web App default URL"
  value       = "https://${azurerm_static_web_app.client.default_host_name}"
}

output "sql_server_fqdn" {
  description = "SQL server hostname (for connecting from tools like Azure Data Studio)"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_admin_password" {
  description = "Generated SQL admin password. Read with: terraform output -raw sql_admin_password"
  value       = random_password.sql_admin.result
  sensitive   = true
}
