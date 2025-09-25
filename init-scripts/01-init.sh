#!/bin/bash
set -e

# Script de inicialización de la base de datos
echo "Inicializando base de datos para Financial Bot..."

# Crear extensiones necesarias
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Crear extensiones útiles para aplicaciones financieras
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    
    -- Configurar timezone
    SET timezone = 'UTC';
    
    -- Crear usuario de solo lectura para reportes
    CREATE USER $POSTGRES_READONLY_USER WITH PASSWORD '$POSTGRES_READONLY_PASSWORD';
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO $POSTGRES_READONLY_USER;
    GRANT USAGE ON SCHEMA public TO $POSTGRES_READONLY_USER;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $POSTGRES_READONLY_USER;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $POSTGRES_READONLY_USER;
    
    -- Mostrar información de la base de datos
    SELECT version();
    
EOSQL

echo "Inicialización de base de datos completada."
echo "Usuario de solo lectura '$POSTGRES_READONLY_USER' creado exitosamente."