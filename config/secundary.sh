#!/usr/bin/env bash
set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils bind9-doc dnsutils

cp /vagrant/files/primario/named /etc/default/named
cp /vagrant/files/secundary/named.conf.options /etc/bind/named.conf.options
cp /vagrant/files/secundary/named.conf.local /etc/bind/named.conf.local

named-checkconf
systemctl restart named
systemctl enable named
