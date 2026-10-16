#!/usr/bin/env bash
set -xeu

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

if [ -f /vagrant/files/info.php ]; then
    cp -vf /vagrant/files/info.php /var/www/html/info.php
fi

systemctl enable --now apache2
systemctl enable --now mariadb || systemctl enable --now mysql
