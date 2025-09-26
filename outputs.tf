output "resource_group_name" {
  description = "Nombre del Resource Group creado"
  value       = azurerm_resource_group.rg.name
}

output "webapp_name" {
  description = "Nombre de la aplicación web"
  value       = azurerm_linux_web_app.app.name
}

output "webapp_default_hostname" {
  description = "URL por defecto de la aplicación web"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "postgres_server_name" {
  description = "Nombre del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.pg.name
}

output "postgres_fqdn" {
  description = "FQDN del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.pg.fqdn
}

output "postgres_database_name" {
  description = "Nombre de la base de datos PostgreSQL"
  value       = azurerm_postgresql_flexible_server_database.db.name
}

output "database_connection_string" {
  description = "String de conexión a la base de datos (sensible)"
  value       = "postgresql://${var.postgres_admin_user}:${var.postgres_admin_pass}@${azurerm_postgresql_flexible_server.pg.fqdn}:5432/${var.postgres_db_name}?sslmode=require"
  sensitive   = true
}

output "webapp_url" {
  description = "The URL of the web app"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.storage.name
}
