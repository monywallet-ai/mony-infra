variable "project" {
  type        = string
  description = "Nombre del proyecto, usado como prefijo para recursos"
  
  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 20
    error_message = "El nombre del proyecto debe tener entre 1 y 20 caracteres."
  }
}

variable "environment" {
  type        = string
  description = "Ambiente de despliegue (dev, staging, prod)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, staging, o prod."
  }
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Región de Azure donde se deployarán los recursos"
}

variable "rg_name" {
  type        = string
  default     = null
  description = "Nombre personalizado del Resource Group. Si es null, se genera automáticamente"
}

variable "app_name" {
  type        = string
  description = "Nombre de la aplicación web (debe ser único globalmente)"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.app_name))
    error_message = "El nombre de la app debe contener solo letras, números y guiones, y no puede empezar o terminar con guión."
  }
}

variable "postgres_admin_user" {
  type        = string
  default     = "pgadmin"
  description = "Usuario administrador de PostgreSQL"
  
  validation {
    condition     = length(var.postgres_admin_user) >= 1 && length(var.postgres_admin_user) <= 63
    error_message = "El usuario admin debe tener entre 1 y 63 caracteres."
  }
}

variable "postgres_admin_pass" {
  type        = string
  sensitive   = true
  description = "Contraseña del administrador de PostgreSQL"
  
  validation {
    condition     = length(var.postgres_admin_pass) >= 8
    error_message = "La contraseña debe tener al menos 8 caracteres."
  }
}

variable "postgres_db_name" {
  type        = string
  default     = "appdb"
  description = "Nombre de la base de datos PostgreSQL"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.postgres_db_name))
    error_message = "El nombre de la base de datos debe empezar con una letra y contener solo letras, números y guiones bajos."
  }
}

variable "allowed_ip" {
  type        = string
  description = "Tu IP pública para acceder a PostgreSQL (formato: x.x.x.x)"
  
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.allowed_ip))
    error_message = "La IP debe estar en formato IPv4 válido (x.x.x.x)."
  }
}

variable "app_service_sku" {
  type        = string
  default     = "B1"
  description = "SKU del App Service Plan"
  
  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2"], var.app_service_sku)
    error_message = "SKU debe ser uno de: B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2."
  }
}

variable "postgres_sku" {
  type        = string
  default     = "B_Standard_B1ms"
  description = "SKU del servidor PostgreSQL (formato: tier_family_cores, ej: B_Standard_B1ms)"
}

variable "postgres_storage_mb" {
  type        = number
  default     = 32768
  description = "Almacenamiento en MB para PostgreSQL (mínimo 32768 = 32GB)"
  
  validation {
    condition     = var.postgres_storage_mb >= 32768
    error_message = "El almacenamiento mínimo es 32768 MB (32 GB)."
  }
}

variable "backup_retention_days" {
  type        = number
  default     = 7
  description = "Días de retención de backups (7-35)"
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Los días de retención deben estar entre 7 y 35."
  }
}

# Security variables
variable "secret_key" {
  description = "Secret key for the application"
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
}

# Storage variables
variable "storage_container_name" {
  description = "Name of the storage container for receipts"
  type        = string
  default     = "receipts"
}

# Storage variables
variable "openai_secret_key" {
  description = "OpenAI secret key"
  type        = string
  sensitive   = true
}

variable "openai_model" {
  description = "OpenAI model"
  type        = string
  default     = "gpt-4o-mini"
}

variable "cors_origins" {
  description = "CORS origins"
  type        = string
  default     = "*"
}
# Documentation access variables
variable "docs_username" {
  description = "Username for accessing the documentation"
  type        = string
  default     = "admin"
}

variable "docs_password" {
  description = "Password for accessing the documentation"
  type        = string
  default     = "admin"
}

# Redis variables
variable "redis_password" {
  description = "Redis password for authentication"
  type        = string
  sensitive   = true
}

variable "redis_memory" {
  description = "Redis container memory in GB"
  type        = number
  default     = 0.5
  
  validation {
    condition     = var.redis_memory >= 0.5 && var.redis_memory <= 2
    error_message = "Redis memory debe estar entre 0.5 y 2 GB."
  }
}

variable "redis_cpu" {
  description = "Redis container CPU cores"
  type        = number
  default     = 0.1
  
  validation {
    condition     = var.redis_cpu >= 0.1 && var.redis_cpu <= 1
    error_message = "Redis CPU debe estar entre 0.1 y 1 core."
  }
}