#!/bin/bash

echo "================================================"
echo "  Tienda Perianza - Instalación desde cero"
echo "================================================"

# Variables
DB_NAME="tienda_db"
DB_USER="tienda_user"
DB_PASS="Tienda2026#"
APP_DIR="/var/www/tienda-perianza"
REPO="https://github.com/perianzanet/tienda-perianza.git"

echo "[1/8] Actualizando sistema..."
apt update && apt upgrade -y

echo "[2/8] Instalando dependencias..."
apt install -y postgresql postgresql-contrib php8.3 php8.3-fpm php8.3-pgsql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-bcmath php8.3-intl php8.3-gd nginx git unzip curl

echo "[3/8] Instalando Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "[4/8] Configurando PostgreSQL..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

echo "[5/8] Clonando repositorio..."
cd /var/www
git clone $REPO
cd $APP_DIR
composer install --no-interaction --prefer-dist --optimize-autoloader
cp .env.example .env
php artisan key:generate

echo "[6/8] Configurando base de datos..."
PGPASSWORD="$DB_PASS" psql -U $DB_USER -h 127.0.0.1 $DB_NAME < $APP_DIR/database/respaldo_tienda_db.sql
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL PRIVILEGES ON TABLE productos TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT USAGE, SELECT, UPDATE ON SEQUENCE productos_id_seq TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT EXECUTE ON FUNCTION sp_productos(JSON, BOOLEAN) TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT EXECUTE ON FUNCTION sp_productos_get(TEXT, TEXT, DATE, DATE) TO $DB_USER;"

echo "[7/8] Configurando Nginx..."
cat > /etc/nginx/sites-available/tienda-perianza << 'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/tienda-perianza/public;
    index index.php;
    charset utf-8;
    location / { try_files $uri $uri/ /index.php?$query_string; }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    error_page 404 /index.php;
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~ /\.(?!well-known).* { deny all; }
}
NGINX
ln -sf /etc/nginx/sites-available/tienda-perianza /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo "[8/8] Ajustando permisos y generando Swagger..."
chown -R www-data:www-data $APP_DIR
chmod -R 775 $APP_DIR/storage
chmod -R 775 $APP_DIR/bootstrap/cache
php artisan config:clear
php artisan l5-swagger:generate
ln -sf $APP_DIR/storage/api-docs $APP_DIR/public/docs

echo "[UFW] Configurando firewall..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

echo "================================================"
echo "  Instalación completada"
echo "  App: http://$(curl -s ifconfig.me)"
echo "  Swagger: http://$(curl -s ifconfig.me)/api/documentation"
echo "  API Key: TiendaPerianza2026#"
echo "================================================"
