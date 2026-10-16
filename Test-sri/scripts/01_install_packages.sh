#!/usr/bin/env bash
set -xeu
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql
