# Mony Infrastructure Makefile
# Automatización de tareas de Terraform para múltiples ambientes

.PHONY: help init validate plan apply destroy clean get-ip setup-dev setup-staging setup-prod

# Variables por defecto
ENV ?= dev
TF_VAR_FILE = environments/$(ENV)/terraform.tfvars
STATE_FILE = terraform-$(ENV).tfstate
PLAN_FILE = $(ENV).tfplan
BACKEND_CONFIG = backend-$(ENV).hcl

# Ayuda (comando por defecto)
help:
	@echo "🚀 Mony Infrastructure - Terraform Automation"
	@echo ""
	@echo "Comandos principales:"
	@echo "  make setup-dev          - Configura ambiente de desarrollo"
	@echo "  make setup-staging      - Configura ambiente de staging"  
	@echo "  make setup-prod         - Configura ambiente de producción"
	@echo ""
	@echo "Gestión de ambientes:"
	@echo "  make init ENV=<env>     - Inicializa Terraform para el ambiente"
	@echo "  make init-local ENV=<env> - Inicializa con backend local (desarrollo)"
	@echo "  make validate ENV=<env> - Valida configuración"
	@echo "  make plan ENV=<env>     - Genera plan de ejecución"
	@echo "  make apply ENV=<env>    - Aplica cambios"
	@echo "  make destroy ENV=<env>  - Destruye infraestructura (¡CUIDADO!)"
	@echo ""
	@echo "Utilidades:"
	@echo "  make get-ip            - Obtiene tu IP pública"
	@echo "  make clean             - Limpia archivos temporales"
	@echo "  make setup-storage     - Ayuda para configurar Azure Storage backend"
	@echo "  make switch-to-local   - Cambia a backend local (desarrollo)"
	@echo ""
	@echo "Ejemplos:"
	@echo "  make plan ENV=dev       - Plan para desarrollo"
	@echo "  make apply ENV=staging  - Deploy a staging"
	@echo "  make destroy ENV=dev    - Destruir desarrollo"
	@echo ""
	@echo "Ambientes disponibles: dev, staging, prod"

# Validar que el ambiente existe
check-env:
	@if [ ! -f "$(TF_VAR_FILE)" ]; then \
		echo "❌ Error: No existe $(TF_VAR_FILE)"; \
		echo "💡 Usa: make setup-$(ENV) para crearlo"; \
		exit 1; \
	fi

# Inicializar Terraform con Azure Storage backend
init:
	@echo "🔧 Inicializando Terraform con backend Azure Storage para $(ENV)..."
	@if [ ! -f "$(BACKEND_CONFIG)" ]; then \
		echo "❌ Error: No existe $(BACKEND_CONFIG)"; \
		echo "💡 Opciones:"; \
		echo "   1. make setup-storage - Configurar Azure Storage"; \
		echo "   2. make init-local ENV=$(ENV) - Usar backend local"; \
		exit 1; \
	fi
	@terraform init -backend-config="$(BACKEND_CONFIG)"

# Inicializar Terraform con backend local (para desarrollo)
init-local:
	@echo "🔧 Inicializando Terraform con backend local para $(ENV)..."
	@echo "⚠️  Usando almacenamiento local - solo recomendado para desarrollo"
	@rm -rf .terraform .terraform.lock.hcl
	@terraform init
	@echo "✅ Inicializado con backend local"
	@echo "📁 Los archivos de estado se almacenarán localmente"

# Validar configuración
validate: check-env
	@echo "✅ Validando configuración para $(ENV)..."
	@terraform validate

# Generar plan
plan: check-env
	@echo "📋 Generando plan para $(ENV)..."
	@terraform plan \
		-var-file="$(TF_VAR_FILE)" \
		-state="$(STATE_FILE)" \
		-out="$(PLAN_FILE)"
	@echo "💾 Plan guardado en: $(PLAN_FILE)"

# Aplicar cambios
apply: check-env
	@if [ -f "$(PLAN_FILE)" ]; then \
		echo "🚀 Aplicando plan pre-generado para $(ENV)..."; \
		terraform apply -state="$(STATE_FILE)" "$(PLAN_FILE)"; \
		rm "$(PLAN_FILE)"; \
	else \
		echo "🚀 Aplicando cambios para $(ENV)..."; \
		terraform apply \
			-var-file="$(TF_VAR_FILE)" \
			-state="$(STATE_FILE)" \
			-auto-approve; \
	fi
	@echo "✅ Despliegue completado para $(ENV)"

# Destruir infraestructura
destroy: check-env
	@echo "💥 ADVERTENCIA: Vas a destruir el ambiente $(ENV)"
	@echo "⚠️  Esta acción es irreversible"
	@read -p "¿Estás seguro? Escribe 'yes' para continuar: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform destroy \
			-var-file="$(TF_VAR_FILE)" \
			-state="$(STATE_FILE)" \
			-auto-approve; \
		echo "💥 Ambiente $(ENV) destruido"; \
	else \
		echo "❌ Operación cancelada"; \
	fi

# Obtener IP pública
get-ip:
	@echo "🌐 Obteniendo tu IP pública..."
	@if command -v curl >/dev/null 2>&1; then \
		IP=$$(curl -s ifconfig.me); \
		echo "Tu IP pública es: $$IP"; \
		echo ""; \
		echo "💡 Úsala en tu archivo terraform.tfvars:"; \
		echo "allowed_ip = \"$$IP\""; \
	else \
		echo "❌ curl no está disponible"; \
	fi

# Configurar Azure Storage para backend remoto
setup-storage:
	@echo "📦 Configuración de Azure Storage para Terraform Backend"
	@echo ""
	@echo "Para usar un backend remoto de Azure Storage, necesitas:"
	@echo ""
	@echo "1. Crear un Storage Account en Azure:"
	@echo "   az group create --name mony-dev-tfstate-rg --location 'East US'"
	@echo "   az storage account create --name monydevterraformstate --resource-group mony-dev-tfstate-rg --location 'East US' --sku Standard_LRS"
	@echo "   az storage container create --name terraform-state-dev --account-name monydevterraformstate"
	@echo ""
	@echo "2. Editar backend-dev.hcl con los nombres correctos de tus recursos"
	@echo ""
	@echo "3. Ejecutar: make init ENV=dev"
	@echo ""
	@echo "💡 Para desarrollo rápido, usa: make init-local ENV=dev"

# Cambiar a backend local
switch-to-local:
	@echo "🔄 Cambiando a backend local..."
	@if [ ! -f "providers-local.tf" ]; then \
		echo "❌ Error: providers-local.tf no existe"; \
		exit 1; \
	fi
	@cp providers.tf providers.tf.azure-backup
	@cp providers-local.tf providers.tf
	@echo "✅ Cambiado a backend local"
	@echo "💡 Para volver a Azure Storage: cp providers.tf.azure-backup providers.tf"

# Configurar ambiente de desarrollo
setup-dev:
	@echo "🛠️  Configurando ambiente de desarrollo..."
	@mkdir -p environments/dev
	@if [ ! -f "environments/dev/terraform.tfvars" ]; then \
		echo "# Configuración para ambiente de desarrollo" > environments/dev/terraform.tfvars; \
		echo "project     = \"mony\"" >> environments/dev/terraform.tfvars; \
		echo "environment = \"dev\"" >> environments/dev/terraform.tfvars; \
		echo "location    = \"East US\"" >> environments/dev/terraform.tfvars; \
		echo "" >> environments/dev/terraform.tfvars; \
		echo "# Configuración de la aplicación web" >> environments/dev/terraform.tfvars; \
		echo "app_name = \"mony-webapp-dev-001\"" >> environments/dev/terraform.tfvars; \
		echo "" >> environments/dev/terraform.tfvars; \
		echo "# Configuración de recursos (optimizada para costos en dev)" >> environments/dev/terraform.tfvars; \
		echo "app_service_sku       = \"B1\"" >> environments/dev/terraform.tfvars; \
		echo "postgres_sku          = \"B1ms\"" >> environments/dev/terraform.tfvars; \
		echo "postgres_storage_mb   = 32768" >> environments/dev/terraform.tfvars; \
		echo "backup_retention_days = 7" >> environments/dev/terraform.tfvars; \
		echo "" >> environments/dev/terraform.tfvars; \
		echo "# Configuración de base de datos" >> environments/dev/terraform.tfvars; \
		echo "postgres_admin_user = \"pgadmin\"" >> environments/dev/terraform.tfvars; \
		echo "postgres_db_name    = \"mony_dev_db\"" >> environments/dev/terraform.tfvars; \
		echo "" >> environments/dev/terraform.tfvars; \
		echo "# IMPORTANTE: Agregar las siguientes variables sensibles" >> environments/dev/terraform.tfvars; \
		echo "# postgres_admin_pass = \"usa-una-contraseña-segura\"" >> environments/dev/terraform.tfvars; \
		echo "# allowed_ip = \"obtener-con-make-get-ip\"" >> environments/dev/terraform.tfvars; \
		echo "✅ Archivo environments/dev/terraform.tfvars creado"; \
	else \
		echo "⚠️  environments/dev/terraform.tfvars ya existe"; \
	fi

# Configurar ambiente de staging
setup-staging:
	@echo "🛠️  Configurando ambiente de staging..."
	@mkdir -p environments/staging
	@if [ ! -f "environments/staging/terraform.tfvars" ]; then \
		echo "# Configuración para ambiente de staging" > environments/staging/terraform.tfvars; \
		echo "project     = \"mony\"" >> environments/staging/terraform.tfvars; \
		echo "environment = \"staging\"" >> environments/staging/terraform.tfvars; \
		echo "location    = \"East US\"" >> environments/staging/terraform.tfvars; \
		echo "" >> environments/staging/terraform.tfvars; \
		echo "app_name = \"mony-webapp-staging\"" >> environments/staging/terraform.tfvars; \
		echo "" >> environments/staging/terraform.tfvars; \
		echo "app_service_sku       = \"S1\"" >> environments/staging/terraform.tfvars; \
		echo "postgres_sku          = \"GP_Standard_D2s_v3\"" >> environments/staging/terraform.tfvars; \
		echo "postgres_storage_mb   = 65536" >> environments/staging/terraform.tfvars; \
		echo "backup_retention_days = 14" >> environments/staging/terraform.tfvars; \
		echo "" >> environments/staging/terraform.tfvars; \
		echo "postgres_admin_user = \"pgadmin\"" >> environments/staging/terraform.tfvars; \
		echo "postgres_db_name    = \"mony_staging_db\"" >> environments/staging/terraform.tfvars; \
		echo "" >> environments/staging/terraform.tfvars; \
		echo "# IMPORTANTE: Configurar variables sensibles" >> environments/staging/terraform.tfvars; \
		echo "# postgres_admin_pass = \"password-diferente-que-dev\"" >> environments/staging/terraform.tfvars; \
		echo "# allowed_ip = \"tu-ip-publica\"" >> environments/staging/terraform.tfvars; \
		echo "✅ Archivo environments/staging/terraform.tfvars creado"; \
	else \
		echo "⚠️  environments/staging/terraform.tfvars ya existe"; \
	fi

# Configurar ambiente de producción
setup-prod:
	@echo "🛠️  Configurando ambiente de producción..."
	@mkdir -p environments/prod
	@if [ ! -f "environments/prod/terraform.tfvars" ]; then \
		echo "# Configuración para ambiente de producción" > environments/prod/terraform.tfvars; \
		echo "project     = \"mony\"" >> environments/prod/terraform.tfvars; \
		echo "environment = \"prod\"" >> environments/prod/terraform.tfvars; \
		echo "location    = \"East US\"" >> environments/prod/terraform.tfvars; \
		echo "" >> environments/prod/terraform.tfvars; \
		echo "app_name = \"mony-webapp\"" >> environments/prod/terraform.tfvars; \
		echo "" >> environments/prod/terraform.tfvars; \
		echo "app_service_sku       = \"P1v2\"" >> environments/prod/terraform.tfvars; \
		echo "postgres_sku          = \"GP_Standard_D4s_v3\"" >> environments/prod/terraform.tfvars; \
		echo "postgres_storage_mb   = 131072" >> environments/prod/terraform.tfvars; \
		echo "backup_retention_days = 35" >> environments/prod/terraform.tfvars; \
		echo "" >> environments/prod/terraform.tfvars; \
		echo "postgres_admin_user = \"pgadmin\"" >> environments/prod/terraform.tfvars; \
		echo "postgres_db_name    = \"mony_prod_db\"" >> environments/prod/terraform.tfvars; \
		echo "" >> environments/prod/terraform.tfvars; \
		echo "# CRÍTICO: Configurar contraseñas súper seguras para producción" >> environments/prod/terraform.tfvars; \
		echo "# postgres_admin_pass = \"password-super-segura-para-prod\"" >> environments/prod/terraform.tfvars; \
		echo "# allowed_ip = \"ip-especifica-para-admin\"" >> environments/prod/terraform.tfvars; \
		echo "✅ Archivo environments/prod/terraform.tfvars creado"; \
	else \
		echo "⚠️  environments/prod/terraform.tfvars ya existe"; \
	fi

# Limpiar archivos temporales
clean:
	@echo "🧹 Limpiando archivos temporales..."
	@rm -f *.tfplan
	@rm -f terraform.tfstate.backup
	@echo "✅ Archivos temporales eliminados"

# Workflow completo para desarrollo
dev-workflow: setup-dev init-local validate plan
	@echo "🎯 Workflow de desarrollo completado"
	@echo "Siguiente paso: make apply ENV=dev"

# Workflow completo para staging
staging-workflow: setup-staging init validate plan
	@echo "🎯 Workflow de staging completado"
	@echo "Siguiente paso: make apply ENV=staging"

# Workflow completo para producción  
prod-workflow: setup-prod init validate plan
	@echo "🎯 Workflow de producción completado"
	@echo "⚠️  REVISAR PLAN CUIDADOSAMENTE ANTES DE: make apply ENV=prod"