Aquí está el script con los comentarios eliminados y reemplazados por nuevos:  

```bash
sudo apt-get update -y
# Actualizo la lista de paquetes del sistema.

sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip curl
# Instalo NFS y las extensiones necesarias de PHP.

mkdir -p /var/nfs/general
# Creo una carpeta para compartir archivos.

sudo chown -R www-data:www-data /var/nfs/general
# Cambio el propietario de la carpeta a www-data.

sudo chmod -R 755 /var/nfs/general
# Ajusto permisos para permitir lectura y ejecución.

sudo echo "/var/nfs/general 192.168.10.100(rw,sync,no_subtree_check)" >> /etc/exports
# Configuro el acceso a la carpeta para la IP 192.168.10.100.

sudo echo "/var/nfs/general 192.168.10.101(rw,sync,no_subtree_check)" >> /etc/exports
# Configuro el acceso a la carpeta para la IP 192.168.10.101.

sudo exportfs -a
# Hago que las configuraciones de NFS estén activas.

sudo systemctl restart nfs-kernel-server
# Reinicio el servidor NFS para aplicar los cambios.

cd /tmp
# Me muevo a la carpeta temporal.

sudo wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
# Descargo el archivo de OwnCloud.

sudo unzip owncloud-10.9.1.zip
# Descomprimo el archivo descargado.

sudo mv owncloud /var/nfs/general/
# Muevo la carpeta de OwnCloud al directorio compartido.

sudo chown -R www-data:www-data /var/nfs/general/owncloud
# Cambio el propietario de la carpeta de OwnCloud a www-data.

sudo chmod -R 755 /var/nfs/general/owncloud
# Ajusto permisos para permitir su uso.

cat <<EOF > /var/nfs/general/owncloud/config/autoconfig.php
# Genero el archivo de configuración automática para OwnCloud.

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
# Configuro la base de datos y los datos iniciales de admin.

sudo sed -i 's/^listen = .*/listen = 192.168.10.200:9000/' /etc/php/7.4/fpm/pool.d/www.conf
# Modifico PHP-FPM para que escuche en la IP del servidor.

sudo sed -i 's/background-color: .*/background-color: #a8d08d;/' /var/nfs/general/owncloud/core/css/styles.css
# Cambio el color de fondo de la interfaz de OwnCloud.

sudo systemctl restart php7.4-fpm
# Reinicio PHP-FPM para aplicar los cambios.

sudo ip route del default
# Borro la ruta por defecto de la red.
```
