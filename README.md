# Nota de instalación

Este archivo funciona para una instalación en ambiente limpio de Linux Debian (VM). Aquí se instalará: Flowise, Docker, Certbot (para la generación de certificado SSL)

## Para ejecutar

SUDO su
docker compose build
docker compose up -d

## Notas importantes:

Asegúrate de que el subdominio apunte a la IP de tu VM

El primer inicio puede tardar hasta 30 segundos mientras se genera el certificado

Para renovaciones automáticas, puedes agregar un cron job en el host:

bash
Copy
0 0 * * * docker-compose -f /ruta/a/tu/docker-compose.yml run --rm certbot renew
Todos los cambios de configuración se hacen mediante el archivo .env