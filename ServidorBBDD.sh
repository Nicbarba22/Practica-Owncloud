Aquí tienes el script con los comentarios eliminados y nuevos añadidos:

```bash
sudo apt-get update -y
# Actualizo los repositorios para obtener los paquetes más recientes.

sudo apt-get install -y mariadb-server
# Instalo MariaDB para la base de datos.

sudo sed -i 's/bind-address.*/bind-address = 192.168.20.160/' /etc/mysql/mariadb.conf.d/50-server.cnf
# Configuro MariaDB para permitir conexiones remotas desde servidores específicos.

sudo systemctl restart mariadb
# Reinicio MariaDB para aplicar los cambios de configuración.

sudo mysql -u root <<EOF
# Accedo a MariaDB como root y ejecuto las siguientes consultas.
CREATE DATABASE owncloud_db;
# Creo la base de datos para OwnCloud.

CREATE USER 'owncloud_user'@'%' IDENTIFIED BY '1234';
# Creo un usuario para OwnCloud con acceso desde cualquier IP.

GRANT ALL PRIVILEGES ON owncloud_db.* TO 'owncloud_user'@'%';
# Le otorgo todos los privilegios al usuario sobre la base de datos.

FLUSH PRIVILEGES;
# Aplico los cambios realizados en los privilegios.
EOF

sudo ip route del default
# Elimino la ruta por defecto de la red.
```
