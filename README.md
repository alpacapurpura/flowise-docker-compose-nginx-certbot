# Nota de instalación

Este archivo funciona para una instalación en ambiente limpio de Linux Debian (VM). Aquí se instalará: Flowise, Docker, Certbot (para la generación de certificado SSL)

## Para ejecutar
1. Se debe crear una carpeta flowise, y allí ingresar:
- SUDO su
- git clone https://github.com/alpacapurpura/flowise-docker-compose-nginx-certbot.git

2. Cambiamos el nombre del archivo .env.template a .env:
- sudo cp env.example .env 

3. Edita el .env con tus valores reales
- sudo nano .env

4. Crea la estructura de carpetas necesaria para la correcta ejecución
- sudo mkdir -p data/certbot/{conf,www}

5. Da permisos a archivo data creado
- sudo chmod -R 755 data

6. Construir ambiente
sudo docker compose build

7. Levantar ambiente
sudo docker compose up -d

## Notas importantes:

Asegúrate de que el subdominio apunte a la IP de tu VM

El primer inicio puede tardar hasta 30 segundos mientras se genera el certificado

Para renovaciones automáticas, puedes agregar un cron job en el host:

- 0 0 * * * docker-compose -f /ruta/a/tu/docker-compose.yml run --rm certbot renew

Todos los cambios de configuración se hacen mediante el archivo .env