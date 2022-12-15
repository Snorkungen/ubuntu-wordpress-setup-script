# Ubuntu Wordpress Setup Script

## stolen from template i'm testing right now

A script that automates  installation of wordpress on ubuntu. Based upon this guide <https://ubuntu.com/tutorials/install-and-configure-wordpress>

>This script assumes you are using systemd systectl

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)

## Installation

```sh
# Install script
git clone https://github.com/Snorkungen/ubuntu-wordpress-setup-script.git

```

## Usage

```sh
# Move into the directory
cd ubuntu-wordpress-setup-script

# Run script
sudo apt update
chmod +x ./script.sh && sudo ./script.sh

```

## Configuration

You can find and edit theese variables at the top of the script.sh file.

```sh
# Name of database where wordpress stores its data.
DB_NAME="wordpress"

# Name of the database user who owns the database.
DB_USER="wordpressuser"

# Password for the user.
DB_PASSWORD="wordpress-password"

# Port that apache will listen on 
PORT=80

# Directory where the wordpress live.
FILE_ROOT=/srv/www

SALT_LENGTH=128
```