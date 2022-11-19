#!/usr/bin/env bash

# Snorkungen 2022

# Credits to
# https://ubuntu.com/tutorials/install-and-configure-wordpress

# https://linuxconfig.org/bash-scripting-cheat-sheet

if [ "$EUID" -ne 0 ]; then
    echo Please run as superuser!
    echo Try running ”sudo $0”.
    exit 1
fi

DB_NAME="wordpress"
DB_USERNAME="wordpressuser"
DB_PASSWORD="wordpress-password"

echo -e "Script Started 🚀"

echo -e "\nInstalling packages\n"

# https://ubuntu.com/tutorials/install-and-configure-wordpress#2-install-dependencies
sudo apt update
sudo apt install -y curl
sudo apt install -y apache2
sudo apt install -y ghostscript
sudo apt install -y libapache2-mod-php
sudo apt install -y mysql-server
sudo apt install -y php
sudo apt install -y php-bcmath
sudo apt install -y php-curl
sudo apt install -y php-imagick
sudo apt install -y php-intl
sudo apt install -y php-json
sudo apt install -y php-mbstring
sudo apt install -y php-mysql
sudo apt install -y php-xml
sudo apt install -y php-zip

echo -e "\nInstalling Wordpress\n"

# https://ubuntu.com/tutorials/install-and-configure-wordpress#3-install-wordpress
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# https://ubuntu.com/tutorials/install-and-configure-wordpress#4-configure-apache-for-wordpress
cp ./wordpress.conf /etc/apache2/sites-available/wordpress.conf

sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default

sudo service apache2 start 
sudo service apache2 reload 

echo -e "\nConfiguring MySQL\n"

# https://ubuntu.com/tutorials/install-and-configure-wordpress#5-configure-database

sudo service mysql start 

sudo mysql -u root <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USERNAME@localhost IDENTIFIED BY '$DB_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON $DB_NAME.* TO  $DB_USERNAME@localhost;
FLUSH PRIVILEGES;
EOF

echo -e "\nConfiguring Wordpress\n"

# https://ubuntu.com/tutorials/install-and-configure-wordpress#6-configure-wordpress-to-connect-to-the-database
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php

sudo -u www-data sed -i 's/database_name_here/'$DB_NAME'/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/'$DB_USERNAME'/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/password_here/'$DB_PASSWORD'/' /srv/www/wordpress/wp-config.php

# Function below generates the a salt
# https://stackoverflow.com/a/23837814

chars=({a..z} {A..Z} {0..9} \, \; \. \: \- \_ \# \* \+ \~ \! \§ \$ \% \& \( \) \= \? \{ \[ \] \} \| \> \<)
SALT_LENGTH=64

function generate_salt {
    local c=$1 ret=
    while ((c--)); do
        ret+=${chars[$((RANDOM % ${#chars[@]}))]}
    done
    printf '%s\n' "$ret"
}

WP_CONFIG_FILE="/srv/www/wordpress/wp-config.php"
SALT=$(generate_salt $SALT_LENGTH)

# Bad solution Incoming
# I cant be bothered to test
while read LINE; do
    sudo sed -E 's/put\syour\sunique\sphrase\shere/'$SALT'/g;' <<< $LINE >> $WP_CONFIG_FILE.temp
    SALT=$(generate_salt $SALT_LENGTH)
done < $WP_CONFIG_FILE

sudo -u www-data rm $WP_CONFIG_FILE
sudo -u www-data mv $WP_CONFIG_FILE.temp $WP_CONFIG_FILE

echo http://localhost
echo Script Done
