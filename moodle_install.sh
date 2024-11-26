#!/bin/bash

# Script that configure moodle 

echo "----------------------------------------------"
echo "-------------- MOODLE SETUP ------------------"
echo "----------------------------------------------"

# Prompt for database name
read -p "Enter the database name (default: moodle_db): " DB_NAME
DB_NAME=${DB_NAME:-"moodle_db"}

# Prompt for database user
read -p "Enter the database user name (default: moodle_user): " DB_USER
DB_USER=${DB_USER:-"moodle_user"}

read -p "What will be your data directory? (default: /var/www/moodledata): " data_directory
data_directory=${data_directory:-"/var/www/moodledata"}



# Prompt for database password
read -sp "Enter the password for the database user: " DB_PASSWORD
echo

# Prompt for installation path
read -p "Enter the moodle installation path (default: /var/www/html/moodle): " MOODLE_PATH
MOODLE_PATH=${MOODLE_PATH:-"/var/www/html/moodle"}

# Prompt for domain or IP
read -p "Enter the domain or IP to access Moodle: " DOMAIN


# Configuration confirmation
echo -e ""
echo -e "========================================================"
echo -e "============ Configuration Summary: ===================="
echo -e "========================================================"
echo -e ""

echo "Database: $DB_NAME"
echo "Database User: $DB_USER"
echo "Installation Path: $MOODLE_PATH"
echo "Domain or IP: $DOMAIN"
echo -e "Do you want to proceed with the installation? (y/n): "

# Confirmation to proceed with the installation
read -n 1 CONFIRM
echo
if [[ "$CONFIRM" != [yY] ]]; then
    echo "Installation canceled."
    exit 1
fi

# Rest of the script for Moodle installation
# Update and upgrade packages
echo "========================================================"
echo "=============== Updating system... ====================="
echo "========================================================"
apt update && apt upgrade -y

# Install Apache
echo "Installing Apache..."
apt install apache2 -y
ufw allow 'Apache Full'

# Install MariaDB
echo "Installing MariaDB..."
apt install mariadb-server -y
mysql_secure_installation

# Create database and user for moodle
echo "Configuring database for Moodle.."
mysql -u root -e "CREATE DATABASE ${DB_NAME};"
mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Install PHP and necessary modules
echo "Installing PHP  and modules..."
sudo apt install -y php php-gd php-json php-mbstring php-curl php-xml php-zip php-mysql php-intl php-bz2 php-imagick php-fpm php-cli libapache2-mod-php php-sqlite3 php-pgsql
sudo apt update
sudo apt install php-curl php-zip

# Configure PHP
echo "Configuring PHP..."
PHP_INI_PATH=$(php -r "echo php_ini_loaded_file();")
sed -i "s/memory_limit = .*/memory_limit = 512M/" "$PHP_INI_PATH"
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 512M/" "$PHP_INI_PATH"
sed -i "s/post_max_size = .*/post_max_size = 512M/" "$PHP_INI_PATH"
sed -i "s/max_execution_time = .*/max_execution_time = 300/" "$PHP_INI_PATH"


# Download and configure Nextcloud
echo "Downloading Moodle..."
sudo apt install git
sudo apt install php-xml
sudo apt install php-mbstring
sudo apt install php-mysqli

git clone https://github.com/moodle/moodle.git
mv moodle $MOODLE_PATH
chown -R www-data:www-data $MOODLE_PATH
chmod -R 755 $MOODLE_PATH

# Make the Moodle data directory

mkdir $data_directory
chown -R www-data:www-data $data_directory
chmod -R 755 $data_directory

# Restart Apache web server
systemctl restart apache2

# Finish
echo "---------------------------------------------------------------------"
echo "Moodle installation complete."
echo "Please access http://$DOMAIN/moodle to complete setup in the browser."
echo "---------------------------------------------------------------------"

