#!/bin/bash

# Script para generar contraseñas aleatorias y configurar el archivo .env
# Uso: ./generate-env.sh

set -e

echo "🔐 Generando contraseñas aleatorias seguras..."

# Verificar que openssl esté disponible
if ! command -v openssl &> /dev/null; then
    echo "❌ Error: openssl no está instalado. Instálalo primero:"
    echo "   Ubuntu/Debian: sudo apt-get install openssl"
    echo "   CentOS/RHEL: sudo yum install openssl"
    echo "   macOS: brew install openssl"
    exit 1
fi

# Verificar si .env ya existe
if [ -f ".env" ]; then
    echo "⚠️  El archivo .env ya existe."
    read -p "¿Deseas sobrescribirlo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operación cancelada."
        exit 1
    fi
fi

# Generar contraseñas aleatorias
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
PGLADMIN_DEFAULT_PASSWORD=$(openssl rand -base64 32)
POSTGRES_READONLY_PASSWORD=$(openssl rand -base64 24)

# Crear el archivo .env
cat > .env << EOF
# Base de datos PostgreSQL
POSTGRES_USER="financebot"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DB="financebot_db"
POSTGRES_HOST="db"
POSTGRES_PORT=5432

# Usuario de solo lectura para reportes
POSTGRES_READONLY_USER="financebot_readonly"
POSTGRES_READONLY_PASSWORD="${POSTGRES_READONLY_PASSWORD}"

# Redis
REDIS_HOST="redis"
REDIS_PORT=6379
REDIS_PASSWORD="${REDIS_PASSWORD}"

# pgAdmin
PGADMIN_DEFAULT_EMAIL="admin@financebot.com"
PGADMIN_DEFAULT_PASSWORD="${PGLADMIN_DEFAULT_PASSWORD}"

# Puertos (cambiar por puertos no estándar para mayor seguridad)
DB_EXTERNAL_PORT=15432
REDIS_EXTERNAL_PORT=16379
PGLADMIN_EXTERNAL_PORT=15050

# Configuración de red
COMPOSE_PROJECT_NAME=financebot

# Configuración de logs
POSTGRES_LOG_LEVEL=warning
REDIS_LOG_LEVEL=notice
EOF

echo "✅ Archivo .env creado exitosamente con contraseñas aleatorias seguras!"
echo ""
echo "📋 Resumen de credenciales generadas:"
echo "   • PostgreSQL: Usuario 'financebot'"
echo "   • PostgreSQL (solo lectura): Usuario 'financebot_readonly'"
echo "   • Redis: Autenticación con contraseña"
echo "   • pgAdmin: admin@financebot.local"
echo ""
echo "🚀 Ahora puedes ejecutar: docker-compose up -d"
echo ""
echo "⚠️  IMPORTANTE: Guarda estas credenciales de forma segura."
echo "   El archivo .env contiene información sensible y está ignorado por git."