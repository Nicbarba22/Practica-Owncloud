Aquí tienes el script con los comentarios eliminados y nuevos añadidos:  

```bash
sudo apt-get update -y
# Actualizo los repositorios para tener la lista de paquetes más reciente.

sudo apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client
# Instalo Nginx, NFS y las extensiones necesarias de PHP.

sudo mkdir -p /var/nfs/general
# Creo una carpeta donde se montará el recurso compartido por NFS.

sudo mount -t nfs 192.168.10.200:/var/nfs/general /var/nfs/general
# Conecto la carpeta compartida del servidor NFS a mi máquina.

sudo echo "192.168.10.200:/var/nfs/general    /var/nfs/general   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
# Configuro el montaje automático de la carpeta NFS en cada reinicio.

cat <<EOF > /etc/nginx/sites-available/default
# Configuro Nginx para servir la aplicación OwnCloud desde la carpeta compartida.
server {
    listen 80;

    root /var/nfs/general/owncloud;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 192.168.10.200:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }
}
EOF

sudo systemctl restart nginx
# Reinicio Nginx para que se aplique la nueva configuración.

sudo systemctl restart php7.4-fpm
# Reinicio PHP-FPM para asegurar que los cambios en PHP estén activos.

sudo ip route del default
# Elimino la ruta por defecto configurada en la red.
```
