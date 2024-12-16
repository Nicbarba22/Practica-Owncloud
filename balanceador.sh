
#!/bin/bash

apt-get update -y
# Actualizo los paquetes.

apt-get install -y nginx
# Instalo Nginx.

cat <<EOF > /etc/nginx/sites-available/default
# Creo la configuración de Nginx.

upstream backend_servers {
    server 192.168.10.100;
    server 192.168.10.101;
}
# Defino los servidores que usaré.

server {
    listen 80;
    server_name localhost;
    # Configuro el servidor.

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
# Envío las peticiones al backend con estas cabeceras.

EOF
# Termino de escribir la configuración.

systemctl restart nginx
# Reinicio Nginx para aplicar cambios.
```
