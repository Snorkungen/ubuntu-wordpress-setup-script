#!/usr/bin/env bash

# Snorkungen 2022

# Credits to
# https://ubuntu.com/tutorials/install-and-configure-wordpress

# https://linuxconfig.org/bash-scripting-cheat-sheet

# This script requires systemd systemctl

if [ "$EUID" -ne 0 ]; then
    echo Please run as superuser! Try running:
    echo sudo "$0"
    exit 1
fi

DB_NAME="wordpress"
DB_USERNAME="wordpressuser"
DB_PASSWORD="wordpress-password"
DB_HOST="localhost"

PORT=80
FILE_ROOT=/srv/www
SALT_LENGTH=128


function echoln() {
    cat <<EOF

        $1
    _______________________________________________________________
EOF
}

function install_dependencies() {
    # Install the required dependencies
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#2-install-dependencies

    echoln "Installing Dependencies"

    apt install apache2 \
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
}

function install_wordpress() {
    # Configure directory for wordpress and install files
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#3-install-wordpress

    mkdir -p $FILE_ROOT
    chown www-data: $FILE_ROOT
    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C $FILE_ROOT
}

function get_apache_wordpress_conf() {
    # Print apache conf
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#4-configure-apache-for-wordpress
    cat <<EOF
<VirtualHost *:$PORT>
    DocumentRoot $FILE_ROOT/wordpress
    <Directory $FILE_ROOT/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory $FILE_ROOT/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
}

function configure_apache() {
    # Configure apache2 for wordpress
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#4-configure-apache-for-wordpress

    echoln "Configuring apache for wordpress"

    get_apache_wordpress_conf >/etc/apache2/sites-available/wordpress.conf

    a2ensite wordpress
    a2enmod rewrite
    a2dissite 000-default

    # Start if apache2 isn't not running
    if ! systemctl is-active --quiet apache2.service; then
        echoln "Starting Apache server"
        systemctl start apache2.service
    fi

    systemctl reload apache2.service
}

function configure_database() {
    # Setup database for wordpress
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#5-configure-database

    echoln "Configuring Database"

    # Start if mysql isn't not running
    if ! systemctl is-active --quiet apache2.service; then
        echoln "Starting mysql server"
        systemctl start mysql.service
    fi

    sudo mysql -u root <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USERNAME@$DB_HOST IDENTIFIED BY '$DB_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON $DB_NAME.* TO  $DB_USERNAME@$DB_HOST;
FLUSH PRIVILEGES;
EOF
}

# Function below generates the a salt
# https://stackoverflow.com/a/23837814
chars=({a..z} {A..Z} {0..9} \, \; \. \: \- \_ \# \* \+ \~ \! \§ \$ \% \& \( \) \= \? \{ \[ \] \} \| \> \<)
function generate_salt {
    local c=$1 ret=
    while ((c--)); do
        ret+=${chars[$((RANDOM % ${#chars[@]}))]}
    done
    printf '%s\n' "$ret"
}

function get_wordpress_config() {
    cat <<EOF

<?php
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USERNAME' );
define( 'DB_PASSWORD', '$DB_PASSWORD' );

define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );

define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         '$(generate_salt $SALT_LENGTH)' );
define( 'SECURE_AUTH_KEY',  '$(generate_salt $SALT_LENGTH)' );
define( 'LOGGED_IN_KEY',    '$(generate_salt $SALT_LENGTH)' );
define( 'NONCE_KEY',        '$(generate_salt $SALT_LENGTH)' );
define( 'AUTH_SALT',        '$(generate_salt $SALT_LENGTH)' );
define( 'SECURE_AUTH_SALT', '$(generate_salt $SALT_LENGTH)' );
define( 'LOGGED_IN_SALT',   '$(generate_salt $SALT_LENGTH)' );
define( 'NONCE_SALT',       '$(generate_salt $SALT_LENGTH)' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}
/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF
}

function configure_wordpress() {
    # Create wp-config.php
    # https://ubuntu.com/tutorials/install-and-configure-wordpress#6-configure-wordpress-to-connect-to-the-database
    echoln "Configuring Wordpress Config"

    get_wordpress_config | sudo -u www-data tee -a $FILE_ROOT/wordpress/wp-config.php > /dev/null
}

echoln "Script Started 🚀"

install_dependencies
install_wordpress
configure_apache
configure_database
configure_wordpress

echoln "Script is Done"
echo "open on http://localhost:$PORT"