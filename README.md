# Nota de instalación

Este archivo funciona para una instalación en ambiente limpio de Linux Debian (VM). Aquí se instalará: Flowise, Docker, Certbot (para la generación de certificado SSL)

## Para ejecutar
1. Descargando la estructura de carpetas:
- SUDO su 
- git clone https://github.com/alpacapurpura/flowise-docker-compose-nginx-certbot.git
- cd flowise-docker-compose-nginx-certbot


2. Generamos el archivo .env tomando como base .env.template:
- sudo cp env.example .env 

3. Edita el .env con tus valores reales
- sudo nano .env

4. Dar permisos de ejecución al script de inicialización
- chmod +x init-letsencrypt.sh

5. Crea los directorios necesarios para Nginx:
- mkdir -p nginx/conf.d nginx/ssl nginx/www

6. Dar permiso a los directorios creados
- sudo chmod -R 755 nginx

7. Ejecuta el script de inicialización para obtener el certificado SSL:
- ./init-letsencrypt.sh

8. Una vez que el certificado esté instalado, inicia todos los servicios:
- docker compose up -d

9. Para ver los logs si hay algún problema:
- docker compose logs -f