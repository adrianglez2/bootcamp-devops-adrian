#!/bin/bash
arte_ascii="
#  .d8b.  d8888b.  .o88b. db   db d888888b d888888b d88888b  .o88b. d888888b db    db d8888b. d88888b #
# d8'  8b 88   8D d8P  Y8 88   88    88     ~~88~~  88      d8P  Y8  ~~88~~  88    88 88   8D 88  #
# 88ooo88 88oobY' 8P      88ooo88    88       88    88ooooo 8P         88    88    88 88oobY  88ooooo #
# 88~~~88 88 8b   8b      88~~~88    88       88    88~~~~~ 8b         88    88    88 88 8b   88~~~~~ #
# 88   88 88  88. Y8b  d8 88   88   .88.      88    88.     Y8b  d8    88    88b  d88 88  88. 88. #
# YP   YP 88   YD   Y88P  YP   YP Y888888P    YP    Y88888P   Y88P     YP    ~Y8888P' 88   YD Y88888P #"

# Comprueba si se esta ejecutando todo el script en modo root, sino ejecuta el escript nuevamente el script con sudo y le pasa todos los argumentos orginales
if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi
# Actualizo los paquetes
sudo apt-get update > /dev/null 

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

########################
##      Variables     ##
########################

# Nombre el respositorio
REPO="bootcamp-devops-2023"

# Lista los paquetes requeridos para la plataforma
PKG=("php libapache2-mod-php php-mysql" "php-mbstring" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" "apache2" "git" "mariadb-server" "libapache2-mod-php" ) 
servicios=("apache2" "mariadb")

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

################################################################################
##      Instalacion/habilitación de paqueteria y clonacion de repositorio     ##
################################################################################

# Verifica si los paquetes estan instalados, y sino los instala cada uno de la lista
for package in "${PKG[@]}"; do
    dpkg -l "$package" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Instalando $package..."
        sudo apt-get install "$package" -y > /dev/null 
    else
        echo "$package ya está instalado."
    fi
done

# Habilita e inicializa los servicios de apache y mariadb
for servicio in "${servicios[@]}"
do
    # Verificar si el servicio está habilitado
    if sudo systemctl is-enabled --quiet $servicio; 
    then
        echo "$servicio ya está habilitado."
    else
        # Si el servicio no está habilitado, habilitarlo y luego iniciarlo
        sudo systemctl enable $servicio > /dev/null 
        sudo systemctl start $servicio > /dev/null 
        echo "Se ha habilitado e iniciado el servicio $servicio."
    fi
done

# Clonación del repositorio
if [-d "$REPO"];
then
    echo "El repositorio $REPO existe, se procede actualizar"
    cd $REPO
    git pull > /dev/null 

else 
    echo "El repositorio $REPO no existe, se procede a clonar.."
    sleep 2
    git clone -b clase2-linux-bash https://github.com/roxsross/bootcamp-devops-2023.git > /dev/null
fi 

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

########################
##     Comprobación   ##
########################

# Comprueba si el archivo index.php existe
if [ -f /var/www/html/index.php ]; 
then
    echo "El archivo index.php existe"
else
    echo "El archivo index.php no existe, se procede a crear"
    cp -r $REPO/app-295devops-travel/* /var/www/html > /dev/null 
fi

# Comprueba si la base de datos existe
if [ -d /var/www/html/database ]; 
then
    echo "La base de datos existe"
else
    echo "La base de datos no existe, se procede a crear"
    mysql < $REPO/app-295devops-travel/database/devopstravel.sql
fi

# Comprueba si el archivo index.html existe, si existe se renombra
if [ -f /var/www/html/index.html ];
then
    echo "si existe"
    mv /var/www/html/index.html /var/www/html/index.html.bk
else
    echo "no existe"
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/apache2/mods-enabled/dir.conf
sudo systemctl restart apache2
sudo systemctl reload apache2
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

####################################
##     Configuración de MariaDB   ##
####################################

echo "Ingrese el usuario: "
read DB_USER
echo "Ingrese la contraseña: "
read DB_PASSWORD
echo "Ingrese el nombre de la base de datos: "
read DB_NAME
#devopstravel
 
$mysql
MariaDB > CREATE DATABASE $DB_NAME;
MariaDB > CREATE USER $DB_USER@'localhost' IDENTIFIED BY $DB_PASSWORD;
MariaDB > GRANT ALL PRIVILEGES ON *.* TO $DB_USER@'localhost';
MariaDB > FLUSH PRIVILEGES;

mysql < database/$DB_NAME.sql
