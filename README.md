# Mony Infrastructure

Este repositorio contiene la infraestructura como código (IaC) para el proyecto Mony usando Terraform y Azure, configurado para múltiples ambientes.

## 🏗️ Arquitectura

La infraestructura incluye:

- **Resource Group**: Contenedor para todos los recursos (por ambiente)
- ## 🛡️ Notas de Seguridad

- El archivo `terraform.tfvars` contiene información sensible y no debe commiterse
- La contraseña de PostgreSQL se almacena en el state de Terraform
- Las conexiones a PostgreSQL usan SSL por defecto
- La regla de firewall `0.0.0.0` para servicios de Azure es solo para desarrollo

### Archivos Sensibles Protegidos por .gitignore

```bash
# Archivos que NUNCA se deben subir al repositorio:
*.tfvars              # Contraseñas y configuración específica
backend-*.hcl         # Nombres de recursos específicos del usuario
*.tfstate*            # Estado de infraestructura (puede contener secretos)

# Verificar que archivos sensibles están protegidos:
git check-ignore -v environments/dev/terraform.tfvars
```

📖 **Ver `.gitignore-guide.md` para detalles completos sobre seguridad de archivos**Service Plan**: Plan de hosting para la aplicación web (Linux)
- **Linux Web App**: Aplicación FastAPI con Python 3.11
- **PostgreSQL Flexible Server**: Base de datos con versión 16
- **Firewall Rules**: Reglas para permitir acceso desde tu IP y servicios de Azure

## 🌍 Ambientes

### Configuración por Ambiente

| Ambiente | App Service | PostgreSQL | Storage | Backup | HA |
|----------|-------------|------------|---------|--------|-----|
| **Dev** | B1 | B1ms | 32 GB | 7 días | No |
| **Staging** | S1 | GP_Standard_D2s_v3 | 64 GB | 14 días | No |
| **Prod** | P1v2 | GP_Standard_D4s_v3 | 128 GB | 35 días | Sí |

### Estructura de Carpetas

```
environments/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars
```

## Prerrequisitos

1. [Terraform](https://www.terraform.io/downloads) >= 1.6.0
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. Una suscripción de Azure activa

## Configuración

### 1. Autenticación con Azure

```bash
az login
az account show  # Verificar la suscripción activa
```

### 2. Configurar variables

Copia el archivo de ejemplo y configura tus valores:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores específicos:

```hcl
project  = "mony-app"
app_name = "mony-webapp-unique-name"  # Debe ser único globalmente
postgres_admin_pass = "TuPasswordSegura123!"
allowed_ip = "123.456.789.012"  # Tu IP pública
```

### 3. Obtener tu IP pública

```bash
curl ifconfig.me
```

## 🚀 Despliegue Rápido

### Opción 1: Desarrollo Local (Recomendado para empezar)

```bash
# 1. Ver todos los comandos disponibles
make help

# 2. Configuración inicial para desarrollo
make setup-dev

# 3. Configurar variables sensibles (ver sección siguiente)

# 4. Workflow completo para desarrollo
make dev-workflow        # setup + init-local + validate + plan
make apply ENV=dev       # aplicar cambios
```

### Opción 2: Backend Remoto Azure Storage (Producción)

```bash
# 1. Configurar Azure Storage
make setup-storage       # Ver instrucciones

# 2. Crear y configurar backend-dev.hcl con tus datos

# 3. Inicializar con backend remoto
make init ENV=dev
make validate ENV=dev
make plan ENV=dev
make apply ENV=dev
```

## 🔑 Configuración de Contraseñas y Variables Sensibles

### Paso a paso para configurar ambiente de desarrollo

```bash
# 1. Configurar estructura base
make setup-dev

# 2. Obtener tu IP pública
make get-ip

# 3. Editar archivo de variables
nano environments/dev/terraform.tfvars
# Agregar las variables que aparecen comentadas:
# postgres_admin_pass = "usa-contraseña-muy-segura"  
# allowed_ip = "tu-ip-obtenida"
```

### 🔒 Recomendaciones de Seguridad para Contraseñas

Para generar contraseñas seguras, usa alguno de estos métodos:

1. **Gestores de contraseñas** (recomendado):
   - 1Password, Bitwarden, LastPass, etc.

2. **Herramientas del sistema** (si es necesario):
   - Usa tu propio método preferido para generar contraseñas
   - Asegúrate de que tenga al menos 16 caracteres
   - Incluye mayúsculas, minúsculas, números y símbolos

3. **Requisitos mínimos**:
   - Mínimo 8 caracteres (recomendado: 16+)
   - No usar palabras del diccionario
   - Diferente para cada ambiente (dev, staging, prod)

## 📊 Variables Disponibles

| Variable | Tipo | Descripción | Requerido | Valor por defecto |
|----------|------|-------------|-----------|-------------------|
| `project` | string | Nombre del proyecto | ✅ | - |
| `environment` | string | Ambiente (dev/staging/prod) | ❌ | "dev" |
| `location` | string | Región de Azure | ❌ | "East US" |
| `rg_name` | string | Nombre del Resource Group | ❌ | `{project}-{env}-rg` |
| `app_name` | string | Nombre de la Web App | ✅ | - |
| `app_service_sku` | string | SKU del App Service | ❌ | "B1" |
| `postgres_admin_user` | string | Usuario admin PostgreSQL | ❌ | "pgadmin" |
| `postgres_admin_pass` | string | Password admin PostgreSQL | ✅ | - |
| `postgres_db_name` | string | Nombre de la base de datos | ❌ | "appdb" |
| `postgres_sku` | string | SKU del servidor PostgreSQL | ❌ | "B1ms" |
| `postgres_storage_mb` | number | Almacenamiento en MB | ❌ | 32768 (32GB) |
| `backup_retention_days` | number | Días de retención de backups | ❌ | 7 |
| `allowed_ip` | string | Tu IP para acceso a PostgreSQL | ✅ | - |

## 🎯 Comandos Útiles con Makefile

### Gestión por Ambiente

```bash
# Configuración inicial de ambientes
make setup-dev           # Configura desarrollo
make setup-staging       # Configura staging  
make setup-prod          # Configura producción

# Workflow completo por ambiente
make dev-workflow        # Prepara desarrollo (setup + init + validate + plan)
make staging-workflow    # Prepara staging
make prod-workflow       # Prepara producción

# Operaciones individuales
make init ENV=dev        # Inicializar Terraform
make validate ENV=dev    # Validar configuración
make plan ENV=dev        # Generar plan
make apply ENV=dev       # Aplicar cambios
make destroy ENV=dev     # Destruir (¡CUIDADO!)
```

### Utilidades

```bash
# Herramientas útiles
make get-ip             # Obtener tu IP pública actual
make clean              # Limpiar archivos temporales (.tfplan)
make help               # Ver todos los comandos disponibles
```

### Ejemplos de Flujo Típico

```bash
# Configurar y desplegar desarrollo desde cero
make setup-dev
# Crear una contraseña segura usando tu método preferido
make get-ip              # Copiar la IP obtenida
# Editar environments/dev/terraform.tfvars con los valores
make dev-workflow
make apply ENV=dev

# Desplegar a staging (después de tener dev funcionando)
make setup-staging
# Configurar variables sensibles en environments/staging/terraform.tfvars
make staging-workflow
make apply ENV=staging

# Desplegar a producción (solo después de testing completo)
make setup-prod
# Configurar variables MUY seguras en environments/prod/terraform.tfvars
make prod-workflow
# REVISAR EL PLAN CUIDADOSAMENTE antes de:
make apply ENV=prod
```

## Outputs

Después del despliegue, obtendrás:

- **webapp_default_hostname**: URL de tu aplicación web
- **postgres_fqdn**: FQDN del servidor PostgreSQL
- **database_connection_string**: String de conexión completo (sensible)

## 💰 Costos Estimados por Ambiente

### Desarrollo (Dev)
- **App Service Plan B1**: ~$13.14/mes
- **PostgreSQL B1ms**: ~$12.41/mes
- **Total estimado**: ~$25.55/mes

### Staging
- **App Service Plan S1**: ~$56.94/mes
- **PostgreSQL GP_Standard_D2s_v3**: ~$146.35/mes
- **Total estimado**: ~$203.29/mes

### Producción (Prod)
- **App Service Plan P1v2**: ~$146.35/mes
- **PostgreSQL GP_Standard_D4s_v3**: ~$292.70/mes
- **High Availability**: ~$292.70/mes adicional
- **Total estimado**: ~$731.75/mes

## 🧹 Limpieza

### Destruir un Ambiente Específico

```bash
# Desarrollo (seguro para testing)
./deploy.sh dev destroy

# Staging (con precaución)
./deploy.sh staging destroy

# Producción (¡EXTREMA PRECAUCIÓN!)
./deploy.sh prod destroy
```

### Limpieza Manual

```bash
# Para ambiente específico
terraform destroy -var-file="environments/dev/terraform.tfvars" -state="terraform-dev.tfstate"
```

## 📁 Estructura del Proyecto

```
.
├── main.tf                           # Recursos principales de Terraform
├── variables.tf                      # Definición de variables
├── outputs.tf                        # Outputs del deployment
├── providers.tf                      # Configuración de providers
├── Makefile                          # Automatización de tareas (⭐ NUEVO)
├── terraform.tfvars                  # Variables para desarrollo (local)
├── terraform.tfvars.example          # Ejemplo de variables
├── environments/                     # Configuraciones por ambiente
│   ├── dev/
│   │   └── terraform.tfvars         # Variables de desarrollo
│   ├── staging/
│   │   └── terraform.tfvars         # Variables de staging
│   └── prod/
│       └── terraform.tfvars         # Variables de producción
├── .gitignore                       # Archivos ignorados por Git
└── README.md                        # Esta documentación
```

### ⭐ Características del Makefile

- **� Interfaz limpia**: Output claro y profesional con emojis
- **🛡️ Validaciones**: Verifica que existan los archivos necesarios
- **🚀 Workflows automatizados**: Comandos combinados para tareas comunes
- **🌐 Detección de IP**: Obtiene automáticamente tu IP pública
- **📋 Help integrado**: `make help` muestra todos los comandos
- **🧹 Limpieza automática**: Elimina archivos temporales
- **🔒 Seguridad**: No incluye funciones que expongan métodos de generación de contraseñas

## Notas de Seguridad

- El archivo `terraform.tfvars` contiene información sensible y no debe commiterse
- La contraseña de PostgreSQL se almacena en el state de Terraform
- Las conexiones a PostgreSQL usan SSL por defecto
- La regla de firewall `0.0.0.0` para servicios de Azure es solo para desarrollo

## Troubleshooting

### Error: nombre de app no único

El nombre de la Web App debe ser único globalmente. Prueba con un nombre diferente.

### Error: IP no permitida para PostgreSQL

Verifica que tu IP esté correcta usando `curl ifconfig.me`.

### Error: password muy simple

La contraseña debe tener al menos 8 caracteres y ser robusta.

---

## ✅ **Setup Completado - Resumen de Mejoras**

### 🔧 **Backend Configuration:**
- ✅ **Backend local por defecto** - Desarrollo rápido sin Azure Storage
- ✅ **Backend Azure Storage** - Configurado para staging/producción  
- ✅ **Archivos de configuración** - backend-*.hcl para cada ambiente
- ✅ **Comandos separados** - `init-local` vs `init`

### 🛠️ **Makefile Mejorado:**
- ✅ **`make init-local ENV=dev`** - Inicialización local instantánea
- ✅ **`make setup-storage`** - Guía completa para Azure Storage
- ✅ **`make dev-workflow`** - Setup completo automatizado
- ✅ **Validaciones integradas** - Verifica archivos antes de ejecutar

### 🔧 **Correcciones Técnicas:**
- ✅ **Recursos actualizados** - `azurerm_postgresql_flexible_server_database`
- ✅ **SKUs corregidos** - `B_Standard_B1ms` formato válido
- ✅ **Alta disponibilidad dinámica** - Solo se activa en producción
- ✅ **Configuración validada** - Terraform validate exitoso

### 🎯 **Inicio Rápido:**

```bash
# 1. Setup ambiente desarrollo (1 comando)
make setup-dev

# 2. Configurar variables sensibles
nano environments/dev/terraform.tfvars
# Agregar: postgres_admin_pass = "tu-password-segura"
#         allowed_ip = "tu-ip" (usar make get-ip)

# 3. Desplegar todo (2 comandos)
make dev-workflow    # setup + init-local + validate + plan
make apply ENV=dev   # ¡Deploy!
```
