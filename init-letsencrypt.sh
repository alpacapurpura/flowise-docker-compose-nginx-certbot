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
cat > ./nginx/conf.d/default.conf.template << EOF
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
docker-compose up --force-recreate -d nginx

# Esperar a que Nginx esté listo
echo "### Esperando a que Nginx esté listo ###"
sleep 10

# Verificar que Nginx esté respondiendo
echo "### Verificando que Nginx esté respondiendo ###"
if ! curl -s http://${domains[0]} > /dev/null; then
    echo "Error: No se puede acceder a http://${domains[0]}"
    echo "Por favor, verifica que:"
    echo "1. El dominio ${domains[0]} resuelve a la IP correcta"
    echo "2. Los puertos 80 y 443 están abiertos en el firewall"
    echo "3. Nginx está corriendo correctamente"
    exit 1
fi

# Eliminar certificados existentes
echo "### Eliminando certificados existentes ###"
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/${domains[0]} && \
  rm -Rf /etc/letsencrypt/archive/${domains[0]} && \
  rm -Rf /etc/letsencrypt/renewal/${domains[0]}.conf" certbot

# Solicitar certificado
echo "### Solicitando certificado ###"
docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    --email $email \
    -d ${domains[0]} \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal" certbot

# Verificar que el certificado se haya creado
if [ ! -f "./nginx/ssl/live/${domains[0]}/fullchain.pem" ]; then
    echo "Error: No se pudo crear el certificado"
    exit 1
fi

# Reemplazar configuración de Nginx con la final
echo "### Reemplazando configuración de Nginx ###"
cat > ./nginx/conf.d/default.conf.template << EOF
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

    # Configuración de seguridad adicional
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Configuración de proxy
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Reiniciar Nginx
echo "### Reiniciando Nginx ###"
docker-compose up -d --force-recreate nginx

echo "### ¡Configuración completada! ###" 