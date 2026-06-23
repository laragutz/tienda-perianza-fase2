# Tienda Perianza

API REST para administración de productos desarrollada como parte de la Evaluación Técnica VPS D.

## Tecnologías

- **SO:** Ubuntu 24.04 LTS
- **Backend:** PHP 8.3 + Laravel 11
- **Base de datos:** PostgreSQL 16
- **Servidor web:** Nginx 1.24
- **Documentación API:** Swagger (L5-Swagger)
- **Exportación:** Maatwebsite Excel

## Arquitectura

    Internet → Nginx (puerto 80) → PHP-FPM 8.3 → Laravel 11 → PostgreSQL 16

## Acceso

- **Aplicación:** http://143.244.188.9
- **API:** http://143.244.188.9/api/productos
- **Swagger:** http://143.244.188.9/api/documentation

## Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /api/productos | Consultar productos con filtros |
| POST | /api/productos | Crear producto |
| PUT | /api/productos/{id} | Actualizar producto |
| DELETE | /api/productos/{id} | Eliminar producto (borrado lógico) |
| GET | /api/productos/export | Exportar a Excel |

### Parámetros GET

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| buscar | string | Busca en nombre, SKU y categoría |
| categoria | string | Filtra por categoría |
| fecha_inicio | date | Fecha inicio YYYY-MM-DD |
| fecha_fin | date | Fecha fin YYYY-MM-DD |

## Instalación

### 1. Requisitos

    apt install -y postgresql postgresql-contrib php8.3 php8.3-fpm php8.3-pgsql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-bcmath php8.3-intl php8.3-gd nginx git unzip curl
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer

### 2. Clonar repositorio

    cd /var/www
    git clone https://github.com/perianzanet/tienda-perianza.git
    cd tienda-perianza
    composer install
    cp .env.example .env
    php artisan key:generate

### 3. Configurar .env

    DB_CONNECTION=pgsql
    DB_HOST=127.0.0.1
    DB_PORT=5432
    DB_DATABASE=tienda_db
    DB_USERNAME=tienda_user
    DB_PASSWORD=tu_password
    SESSION_DRIVER=file
    CACHE_STORE=file
    QUEUE_CONNECTION=sync

### 4. Base de datos

    sudo -u postgres psql -c "CREATE USER tienda_user WITH PASSWORD 'tu_password';"
    sudo -u postgres psql -c "CREATE DATABASE tienda_db OWNER tienda_user;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tienda_db TO tienda_user;"
    sudo -u postgres psql -d tienda_db < database/respaldo_tienda_db.sql
    sudo -u postgres psql -d tienda_db -c "GRANT ALL PRIVILEGES ON TABLE productos TO tienda_user;"
    sudo -u postgres psql -d tienda_db -c "GRANT USAGE, SELECT, UPDATE ON SEQUENCE productos_id_seq TO tienda_user;"
    sudo -u postgres psql -d tienda_db -c "GRANT EXECUTE ON FUNCTION sp_productos(JSON, BOOLEAN) TO tienda_user;"
    sudo -u postgres psql -d tienda_db -c "GRANT EXECUTE ON FUNCTION sp_productos_get(TEXT, TEXT, DATE, DATE) TO tienda_user;"

### 5. Permisos

    chown -R www-data:www-data /var/www/tienda-perianza
    chmod -R 775 /var/www/tienda-perianza/storage
    chmod -R 775 /var/www/tienda-perianza/bootstrap/cache

### 6. Nginx

Crear /etc/nginx/sites-available/tienda-perianza:

    server {
        listen 80;
        server_name tu_ip;
        root /var/www/tienda-perianza/public;
        index index.php;
        charset utf-8;
        location / { try_files $uri $uri/ /index.php?$query_string; }
        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }

    ln -s /etc/nginx/sites-available/tienda-perianza /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx

### 7. Swagger

    php artisan l5-swagger:generate
    ln -s /var/www/tienda-perianza/storage/api-docs /var/www/tienda-perianza/public/docs

## Migración MySQL → PostgreSQL

1. Se analizó la estructura de la BD origen tienda_origen 
2. Se adaptaron los tipos de datos:
   - INT AUTO_INCREMENT → SERIAL
   - TINYINT(1) → BOOLEAN
   - DATETIME → TIMESTAMP
3. Se crearon stored procedures en PostgreSQL:
   - sp_productos(json, boolean) — MERGE para INSERT/UPDATE/DELETE lógico
   - sp_productos_get(text, text, date, date) — consulta con filtros
4. Se migró la información y verificó integridad con SELECT COUNT(*)

## Respaldo y Restauración

Generar respaldo:

    PGPASSWORD=Tienda2026# pg_dump -U tienda_user -h 127.0.0.1 tienda_db > respaldo_tienda_db.sql

Restaurar respaldo:

    PGPASSWORD=Tienda2026# psql -U tienda_user -h 127.0.0.1 tienda_db < respaldo_tienda_db.sql

## Seguridad implementada

### API Key

Todos los endpoints requieren el header:

    X-API-KEY: TiendaPerianza2026#

O como query parameter:

    ?api_key=TiendaPerianza2026#

- Firewall UFW habilitado (puertos 22, 80, 443)
- Nginx como proxy reverso
- Usuario de BD con privilegios mínimos
- Validaciones en stored procedures y controlador
- Borrado lógico mediante campo activo

## Autor

**Eliseo Perianza**
GitHub: @perianzanet
