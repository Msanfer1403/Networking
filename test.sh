#!/usr/bin/env bash
echo "Comprobación de sintaxis de ficheros"
named-checkconf /etc/bind/named.conf.options && echo "named.conf.options"
named-checkzone maximo.test /var/lib/bind/maximo.test.dns && echo "Zona directa"
named-checkzone 56.168.192.in-addr.arpa /var/lib/bind/maximo.test.rev && echo "Zona inversa"

echo "Comprobación de resolución"
dig @localhost debian.maximo.test A +short
dig @localhost web.maximo.test CNAME +short
dig @localhost maximo.test TXT +short
dig @localhost -x 192.168.56.10 +short
