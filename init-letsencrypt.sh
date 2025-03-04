#!/bin/bash

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

domains=(${NGINX_DOMAIN})
email=${NGINX_SSL_EMAIL}
staging=0 # Set to 1 if you're testing your setup

# Crear directorios necesarios
mkdir -p ./nginx/ssl
mkdir -p ./nginx/conf.d
mkdir -p ./nginx/www

# Crear archivo de configuración de Nginx temporal
echo "### Creando configuración temporal de Nginx ###"
cat > ./nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name \${NGINX_DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# Iniciar Nginx
echo "### Iniciando Nginx ###"
docker compose up --force-recreate -d nginx

# Eliminar certificados existentes
echo "### Eliminando certificados existentes ###"
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/${domains[0]} && \
  rm -Rf /etc/letsencrypt/archive/${domains[0]} && \
  rm -Rf /etc/letsencrypt/renewal/${domains[0]}.conf" certbot

# Solicitar certificado
echo "### Solicitando certificado ###"
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    --email $email \
    -d ${domains[0]} \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal" certbot

# Reemplazar configuración de Nginx con la final
echo "### Reemplazando configuración de Nginx ###"
cat > ./nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name \${NGINX_DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name \${NGINX_DOMAIN};

    ssl_certificate /etc/letsencrypt/live/\${NGINX_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/\${NGINX_DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://flowise:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Reiniciar Nginx
echo "### Reiniciando Nginx ###"
docker compose up -d --force-recreate nginx

echo "### ¡Configuración completada! ###" 