#!/usr/bin/env bash
set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils bind9-doc dnsutils

# Confg de BIND
cp /vagrant/files/primary/named /etc/default/named
cp /vagrant/files/primary/named.conf.options /etc/bind/named.conf.options
cp /vagrant/files/primary/named.conf.local /etc/bind/named.conf.local

# Ficheros de zona
cp /vagrant/files/primary/maximo.test.dns /var/lib/bind/maximo.test.dns
cp /vagrant/files/primary/maximo.test.rev /var/lib/bind/maximo.test.rev
chown root:bind /var/lib/bind/maximo.test.dns /var/lib/bind/maximo.test.rev
chmod 644 /var/lib/bind/maximo.test.dns /var/lib/bind/maximo.test.rev

# Validar antes de reiniciar
named-checkconf
systemctl restart named
systemctl enable named
