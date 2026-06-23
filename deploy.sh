#!/bin/bash

echo "================================================"
echo "  Tienda Perianza - Script de Despliegue"
echo "================================================"

cd /var/www/tienda-perianza

echo "[1/5] Actualizando código..."
git pull origin main

echo "[2/5] Instalando dependencias..."
composer install --no-interaction --prefer-dist --optimize-autoloader

echo "[3/5] Limpiando caché..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

echo "[4/5] Generando Swagger..."
php artisan l5-swagger:generate

echo "[5/5] Ajustando permisos..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo "================================================"
echo "  Despliegue completado exitosamente"
echo "================================================"
