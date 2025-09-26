locals {
  environment_suffix = var.environment == "prod" ? "" : "-${var.environment}"
  rg_name            = coalesce(var.rg_name, "${var.project}${local.environment_suffix}-rg")
  plan_name          = "${var.project}${local.environment_suffix}-plan"
  webapp_name        = var.environment == "prod" ? var.app_name : "${var.app_name}-${var.environment}"
  pg_name            = replace("${var.project}${local.environment_suffix}-pg", "_", "-")
  
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location

  tags = local.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = local.plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = local.common_tags
}

# Web App (API FastAPI)
resource "azurerm_linux_web_app" "app" {
  name                = local.webapp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = var.environment == "prod" ? true : false
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"         = "0"
    "PYTHON_ENABLE_WORKER_EXTENSIONS"  = "1"
    "DATABASE_URL"                     = "postgresql://${var.postgres_admin_user}:${var.postgres_admin_pass}@${azurerm_postgresql_flexible_server.pg.fqdn}:5432/${var.postgres_db_name}?sslmode=require"
    "ENVIRONMENT"                      = var.environment
    "DEBUG"                           = var.environment == "dev" ? "true" : "false"
  }

  depends_on = [azurerm_postgresql_flexible_server_database.db]

  tags = local.common_tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = local.pg_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_pass

  sku_name   = var.postgres_sku
  storage_mb = var.postgres_storage_mb
  version    = "16"

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false
  
  dynamic "high_availability" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  public_network_access_enabled = true

  tags = merge(local.common_tags, {
    Tier = "Database"
  })
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Regla de firewall para permitir tu IP
resource "azurerm_postgresql_flexible_server_firewall_rule" "my_ip" {
  name             = "allow-my-ip"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = var.allowed_ip
  end_ip_address   = var.allowed_ip
}

# Regla de firewall para permitir servicios de Azure
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
