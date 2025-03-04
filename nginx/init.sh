#!/bin/sh

# Reemplazar variables en el archivo de configuración
envsubst '${NGINX_DOMAIN}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Iniciar Nginx
exec nginx -g 'daemon off;' 