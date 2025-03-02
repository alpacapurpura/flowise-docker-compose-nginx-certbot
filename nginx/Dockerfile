# Stage 1: Build stage
FROM nginx:alpine

# Instalar envsubst para reemplazar variables
RUN apk add --no-cache gettext

# Copiar plantilla de configuración
COPY nginx.conf.template /etc/nginx/templates/nginx.conf

# Script de entrada para procesar variables
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]