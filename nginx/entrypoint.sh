#!/bin/sh
# Procesar variables en plantilla
envsubst '${DOMAIN} ${FLOWISE_PORT}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# Ejecutar el comando original de Nginx
exec "$@"