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
DB_USERNAME="wordpress"
DB_PASSWORD="wordpress-password"

echo -e "Script Started 🚀"

# https://ubuntu.com/tutorials/install-and-configure-wordpress#2-install-dependencies
sudo apt update
sudo apt install apache2 \
    ghostscript \
    libapache2-mod-php \
    mysql-server \
    php \
    php-bcmath \
    php-curl \
    php-imagick \
    php-intl \
    php-json \
    php-mbstring \
    php-mysql \
    php-xml \
    php-zip

# https://ubuntu.com/tutorials/install-and-configure-wordpress#3-install-wordpress
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# https://ubuntu.com/tutorials/install-and-configure-wordpress#4-configure-apache-for-wordpress
cp ./wordpress.conf /etc/apache2/sites-available/wordpress.conf

sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default

sudo systemctl reload apache2

# https://ubuntu.com/tutorials/install-and-configure-wordpress#5-configure-database
sudo systemctl start mysql

sudo mysql -u root <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USERNAME@localhost IDENTIFIED BY '$DB_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON $DB_USERNAME.* TO  $DB_NAME@localhost;
FLUSH PRIVILEGES;
EOF

# https://ubuntu.com/tutorials/install-and-configure-wordpress#6-configure-wordpress-to-connect-to-the-database
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php

sudo -u www-data sed -i 's/'$DB_NAME'/wordpress/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/'$DB_USERNAME'/wordpress/' /srv/www/wordpress/wp-config.php
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


WP_CONFIG_LOCATION="./wp-config.php"

# Todo pls fix! 
#Salt will be the same for all which is not good

sudo  sed -i -E 's/put\syour\sunique\sphrase\shere/'$(generate_salt $SALT_LENGTH)'/1;' $WP_CONFIG_LOCATION

echo http://localhost

echo Script Done
