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
      python_version = "3.12"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"         = "0"
    "PYTHON_ENABLE_WORKER_EXTENSIONS"  = "1"
    
    # Database
    "DATABASE_URL"                     = "postgresql://${var.postgres_admin_user}:${var.postgres_admin_pass}@${azurerm_postgresql_flexible_server.pg.fqdn}:5432/${var.postgres_db_name}?sslmode=require"
    
    # Environment
    "ENVIRONMENT"                      = var.environment
    "DEBUG"                           = var.environment == "dev" ? "true" : "false"
    
    # Security - NUEVAS VARIABLES
    "SECRET_KEY"                       = var.secret_key
    "JWT_SECRET_KEY"                   = var.jwt_secret_key
    "ALGORITHM"                        = "HS256"
    "ACCESS_TOKEN_EXPIRE_MINUTES"      = "30"
    
    # Azure Storage - NUEVAS VARIABLES
    "AZURE_STORAGE_CONNECTION_STRING"  = azurerm_storage_account.storage.primary_connection_string
    "AZURE_CONTAINER_NAME"             = var.storage_container_name
  }

  depends_on = [
    azurerm_postgresql_flexible_server_database.db,
    azurerm_storage_container.receipts  # Nueva dependencia
  ]

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

# Storage Account for receipts
resource "azurerm_storage_account" "storage" {
  name                     = "${substr(replace("${var.project}${local.environment_suffix}st", "-", ""), 0, 24)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  account_tier            = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  
  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = local.common_tags
}

# Storage Container for receipts
resource "azurerm_storage_container" "receipts" {
  name                 = var.storage_container_name
  storage_account_name = azurerm_storage_account.storage.name
  container_access_type = "private"
}