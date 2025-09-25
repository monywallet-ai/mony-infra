# Fina### 1. Configuración de Variables de Entorno

#### Opción A: Script Automático (Recomendado)

```bash
# Genera automáticamente todas las contraseñas y crea el archivo .env
./generate-env.sh
```

#### Opción B: Configuración Manual

```bash
# Copia el archivo de ejemplo
cp .env.example .env
```

**Genera contraseñas seguras aleatorias:**

```bash
# Generar contraseñas aleatorias seguras
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)"
echo "REDIS_PASSWORD=$(openssl rand -base64 32)"
echo "PGLADMIN_DEFAULT_PASSWORD=$(openssl rand -base64 32)"
echo "POSTGRES_READONLY_PASSWORD=$(openssl rand -base64 24)"
```

Copia las contraseñas generadas y pégalas en tu archivo `.env` reemplazando los valores de ejemplo.Docker Setup

Este proyecto utiliza Docker Compose para orquestar los servicios necesarios para el Financial Bot.

## 🚀 Configuración Inicial

### 1. Configuración de Variables de Entorno

Copia el archivo de ejemplo y configura tus variables:

```bash
cp .env.example .env
```

Edita el archivo `.env` y cambia las contraseñas por unas seguras:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD` 
- `PGADMIN_DEFAULT_PASSWORD`

### 2. Ejecutar los Servicios

```bash
# Ejecutar en segundo plano
docker-compose up -d

# Ver los logs
docker-compose logs -f

# Verificar el estado de los servicios
docker-compose ps
```

## 🔧 Servicios Incluidos

### PostgreSQL (Base de Datos)
- **Puerto:** 15432 (configurable via `DB_EXTERNAL_PORT`)
- **Usuario principal:** `financebot` (configurable)
- **Usuario solo lectura:** `financebot_readonly` (configurable)
- **Base de datos:** `financebot_db`
- **Health check:** Activo
- **Extensiones:** uuid-ossp, pgcrypto, pg_stat_statements

### Redis (Cache/Sesiones)
- **Puerto:** 16379 (configurable via `REDIS_EXTERNAL_PORT`)
- **Autenticación:** Habilitada con contraseña
- **Persistencia:** AOF habilitada
- **Health check:** Activo

### pgAdmin (Interfaz Web para PostgreSQL)
- **Puerto:** 15050 (configurable via `PGADMIN_EXTERNAL_PORT`)
- **URL:** http://localhost:15050
- **Usuario:** Configurado en `.env`

## 🔒 Características de Seguridad

- **Contraseñas seguras:** Todas las contraseñas están en variables de entorno
- **Puertos no estándar:** Se usan puertos alternativos para mayor seguridad
- **Red aislada:** Los servicios se comunican en una red Docker privada
- **Health checks:** Monitoreo automático de la salud de los servicios
- **Security options:** `no-new-privileges` habilitado
- **Logging limitado:** Rotación automática de logs
- **Read-only filesystems:** Donde es posible

## 📊 Comandos Útiles

```bash
# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (¡CUIDADO! Se perderán los datos)
docker-compose down -v

# Reconstruir las imágenes
docker-compose build --no-cache

# Ver logs de un servicio específico
docker-compose logs -f db
docker-compose logs -f redis
docker-compose logs -f pgadmin

# Entrar al contenedor de PostgreSQL
docker-compose exec db psql -U financebot -d financebot_db

# Entrar al contenedor de Redis
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD}

# Backup de la base de datos
docker-compose exec db pg_dump -U financebot financebot_db > backup.sql

# Restaurar backup
docker-compose exec -T db psql -U financebot financebot_db < backup.sql
```

## 🔍 Monitoreo y Health Checks

Los servicios incluyen health checks automáticos. Puedes verificar su estado con:

```bash
docker-compose ps
```

## 🚨 Consideraciones de Producción

Para un entorno de producción, considera:

1. **Usar Docker Secrets** en lugar de variables de entorno para contraseñas
2. **Configurar SSL/TLS** para las conexiones
3. **Implementar backups automáticos**
4. **Usar un reverse proxy** (nginx, traefik) con SSL
5. **Configurar firewall** para limitar acceso a los puertos
6. **Monitoreo** con Prometheus/Grafana
7. **Limitar recursos** de CPU y memoria para cada contenedor

## 📁 Estructura del Proyecto

```
financial-bot/
├── docker-compose.yml     # Configuración de servicios
├── .env                   # Variables de entorno (no subir a git)
├── .env.example          # Plantilla de variables de entorno
├── .gitignore           # Archivos a ignorar en git
├── generate-env.sh      # Script para generar contraseñas automáticamente
├── init-scripts/        # Scripts de inicialización de BD
│   └── 01-init.sh      # Script de configuración inicial
└── README.md           # Este archivo
```

## 🆘 Solución de Problemas

### Error de conexión a la base de datos
```bash
# Verificar que el contenedor esté corriendo
docker-compose ps

# Ver logs del servicio de base de datos
docker-compose logs db
```

### Problemas con Redis
```bash
# Verificar conexión a Redis
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} ping
```

### pgAdmin no carga
```bash
# Verificar logs de pgAdmin
docker-compose logs pgadmin

# Verificar que la base de datos esté lista
docker-compose exec db pg_isready -U financebot
```