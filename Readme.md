
# Introducción
Este conjunto de scripts configura una infraestructura de alta disponibilidad para OwnCloud utilizando una arquitectura de múltiples servidores. Se implementa un balanceador de carga con Nginx para distribuir el tráfico entre dos servidores backend, asegurando un rendimiento óptimo. Además, se configura un servidor NFS para compartir una carpeta con OwnCloud, lo que permite que diferentes servidores web accedan y gestionen los mismos datos. Finalmente, se establece una base de datos en MariaDB, accesible de forma remota, que alberga la información necesaria para OwnCloud.
## Balanceador

Este script configura un balanceador de carga con **Nginx**. Primero, actualiza los paquetes del sistema e instala Nginx. 
Luego, crea una configuración donde define dos servidores backend a los cuales se redirigirán las solicitudes entrantes. 
Utiliza la directiva `proxy_pass` para distribuir el tráfico entre estos servidores y establece cabeceras HTTP necesarias para manejar correctamente las peticiones. Finalmente, reinicia Nginx para aplicar los cambios. 
El objetivo es equilibrar la carga entre los dos servidores backend y mejorar el rendimiento y la disponibilidad del servicio.

```bash
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
## Servidor NFS
```
Este script configura un servidor NFS para compartir una carpeta con OwnCloud y establece las dependencias necesarias para su funcionamiento.
Primero, actualiza el sistema e instala paquetes como NFS, PHP y varias extensiones necesarias para OwnCloud. Luego, crea una carpeta compartida, ajusta los permisos y configura NFS para que esta carpeta sea accesible desde dos servidores específicos. Después, reinicia el servicio NFS para aplicar los cambios. A continuación, descarga e instala OwnCloud en la carpeta compartida, ajusta los permisos correspondientes y crea un archivo de configuración inicial para conectar OwnCloud a una base de datos MySQL.
Finalmente, configura PHP-FPM para que escuche en la IP del servidor NFS y reinicia el servicio PHP-FPM para que los cambios tomen efecto.

sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip curl

# Crear carpeta compartida para OwnCloud y configurar permisos
mkdir -p /var/nfs/general
sudo chown -R www-data:www-data /var/nfs/general
sudo chmod -R 755 /var/nfs/general

# Configurar NFS para compartir la carpeta
sudo echo "/var/nfs/general 192.168.10.100(rw,sync,no_subtree_check)" >> /etc/exports
sudo echo "/var/nfs/general 192.168.10.101(rw,sync,no_subtree_check)" >> /etc/exports

# Reiniciar NFS para aplicar cambios
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Descargar y configurar OwnCloud
cd /tmp
sudo wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
sudo unzip owncloud-10.9.1.zip
sudo mv owncloud /var/nfs/general/

# Configurar permisos de OwnCloud
sudo chown -R www-data:www-data /var/nfs/general/owncloud
sudo chmod -R 755 /var/nfs/general/owncloud

# Crear archivo de configuración inicial para OwnCloud
cat <<EOF > /var/nfs/general/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype" => "mysql",
  "dbname" => "owncloud_db",
  "dbuser" => "owncloud_user",
  "dbpassword" => "1234",
  "dbhost" => "192.168.20.160",
  "directory" => "/var/nfs/general/owncloud/data",
  "adminlogin" => "admin",
  "adminpass" => "1234"
);
EOF

# Configuración de PHP-FPM para escuchar en la IP del servidor NFS
sudo sed -i 's/^listen = .*/listen = 192.168.10.200:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Reiniciar PHP-FPM
sudo systemctl restart php7.4-fpm

sudo ip route del default
```

## Servidor Backend
Este script configura un cliente NFS con Nginx para servir **OwnCloud**. Primero, actualiza el sistema e instala los paquetes necesarios como Nginx, PHP, MariaDB y NFS. Luego, crea un directorio en el cliente donde se montará la carpeta compartida desde el servidor NFS y monta esta carpeta de forma temporal. Para asegurar que el montaje sea persistente, agrega una entrada al archivo `/etc/fstab`. A continuación, configura **Nginx** para servir **OwnCloud** desde la carpeta compartida, especificando la raíz del sitio y asegurando que las solicitudes PHP se gestionen correctamente a través de PHP-FPM.
Finalmente, reinicia Nginx y PHP-FPM para aplicar la configuración y borra la ruta por defecto para asegurar una correcta conectividad.
```
sudo apt-get update -y
sudo apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client

# Crear directorio para montar la carpeta compartida por NFS
sudo mkdir -p /var/nfs/general

# Montar la carpeta NFS desde el servidor NFS
sudo mount -t nfs 192.168.10.200:/var/nfs/general /var/nfs/general

# Añadir entrada al /etc/fstab para montaje persistente
sudo echo "192.168.10.200:/var/nfs/general    /var/nfs/general   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
# Configuración de Nginx para servir OwnCloud
cat <<EOF > /etc/nginx/sites-available/default
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

# Reiniciar Nginx para aplicar los cambios
sudo systemctl restart nginx

# Reiniciar PHP-FPM 7.4
sudo systemctl restart php7.4-fpm

sudo ip route del default
```

## Servidor Base de Datos
Este script configura **MariaDB** para que sea accesible de forma remota desde otros servidores y crea una base de datos y usuario para **OwnCloud**. Primero, actualiza el sistema e instala **MariaDB**. Luego, ajusta la configuración de **MariaDB** para permitir conexiones remotas modificando el archivo de configuración y especificando la dirección IP del servidor de base de datos. Después, reinicia **MariaDB** para aplicar los cambios. A continuación, se crea la base de datos `owncloud_db`, un usuario `owncloud_user` con privilegios completos sobre la base de datos y se configura para que pueda conectarse desde cualquier servidor (`%`).
Finalmente, se asegura de que los cambios de privilegios se apliquen correctamente.
```
sudo apt-get update -y
sudo apt-get install -y mariadb-server

# Configurar MariaDB para permitir acceso remoto desde los servidores web
sudo sed -i 's/bind-address.*/bind-address = 192.168.20.160/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Reiniciar MariaDB
sudo systemctl restart mariadb

# Crear base de datos y usuario para OwnCloud
sudo mysql -u root <<EOF
CREATE DATABASE owncloud_db;
CREATE USER 'owncloud_user'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON owncloud_db.* TO 'owncloud_user'@'%';
FLUSH PRIVILEGES;
EOF

sudo ip route del default
```
## Conclusión
Con la configuración de los servidores Nginx, NFS y MariaDB, se logra una solución escalable y redundante para alojar OwnCloud. El uso del balanceador de carga mejora la disponibilidad y el rendimiento del sistema, mientras que el servidor NFS centraliza el almacenamiento de datos, y la base de datos en MariaDB asegura el acceso remoto y la integridad de la información. Este enfoque garantiza que el sistema sea fiable y eficiente, incluso bajo cargas altas o en entornos distribuidos.
