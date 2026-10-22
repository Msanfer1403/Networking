## Doc with img
Autor: Maximo (GitHub: maximo-sf)

## 1. Introducción

El DNS (Domain Name System) es un sistema de nombres **jerárquico**: la raíz (`.`)
delega en dominios de primer nivel (`.es`, `.com`, `.test`...), y estos en
dominios de segundo nivel y subdominios. Un nombre completo (FQDN) se lee de
derecha a izquierda, por ejemplo `debian.maximo.test.`

Conceptos usados en la práctica:

- **Zona**: parte del espacio de nombres que administra un servidor. Hay zona **directa** (nombre → IP) e **inversa** (IP → nombre).
- **Servidor primario (maestro)**: tiene el fichero de zona original.
- **Servidor secundario (esclavo)**: recibe una copia por transferencia de zona.
- **Registros**: `SOA` (datos de la zona), `NS` (servidores de nombres), `A` (nombre → IPv4), `CNAME` (alias), `TXT` (texto), `PTR` (IP → nombre).

## 2. Entorno

| Elemento | Valor |
|----------|-------|
| Anfitrión | Windows |
| Virtualización | VirtualBox + Vagrant |
| Sistema invitado | Debian 12 (`debian/bookworm64`) |
| Dominio | `maximo.test` |
| Red privada | `192.168.56.0/24` |
| Primario | `192.168.56.10` (`debian`) |
| Secundario | `192.168.56.11` (`debian2`) |

## 3. Creación de la máquina virtual

Comando usado: `vagrant up`

> **CAPTURA**: arranque de la máquina con `vagrant up` y `vagrant ssh`.

## 4. Instalación de BIND9

```bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc dnsutils
```

> **CAPTURA**: instalación terminada y `named -v`.

## 5. Configuración del servidor primario

### 5.1 Solo IPv4 (`/etc/default/named`)

```
OPTIONS="-u bind -4"
```

### 5.2 `named.conf.options`

Copia de seguridad antes de editar:

```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
```

Contenido final: ver [`files/primario/named.conf.options`](../files/primario/named.conf.options).

Explicación de las opciones principales:

- `acl confiables`: solo estos hosts pueden hacer consultas recursivas.
- `allow-transfer { none; }`: por defecto no se permiten transferencias de zona.
- `listen-on`: escucha en el puerto 53 en localhost y en la IP privada.
- `recursion yes` + `allow-recursion`: recursión solo para la ACL.
- `dnssec-validation auto`: validación DNSSEC habilitada.
- `listen-on-v6` comentado: no se atienden consultas IPv6.

```bash
named-checkconf /etc/bind/named.conf.options
sudo systemctl restart named
sudo systemctl status named
```

> **CAPTURA**: `named-checkconf` sin errores y `systemctl status named` activo.

### 5.3 `named.conf.local`

Declaración de las zonas directa e inversa como `master`.
Ver [`files/primario/named.conf.local`](../files/primario/named.conf.local).

### 5.4 Zona directa

Fichero `/var/lib/bind/maximo.test.dns`.
Ver [`files/primario/maximo.test.dns`](../files/primario/maximo.test.dns).

### 5.5 Zona inversa

Fichero `/var/lib/bind/maximo.test.rev`.
Ver [`files/primario/maximo.test.rev`](../files/primario/maximo.test.rev).

### 5.6 Comprobación de la configuración

```bash
named-checkzone maximo.test /var/lib/bind/maximo.test.dns
named-checkzone 56.168.192.in-addr.arpa /var/lib/bind/maximo.test.rev
sudo systemctl restart named
sudo systemctl status named
```

> **CAPTURA**: ambas zonas con `OK` y el log con las zonas cargadas (`loaded serial`).

## 6. Comprobación con `dig` y `nslookup`

```bash
dig @192.168.56.10 debian.maximo.test
nslookup debian.maximo.test 192.168.56.10
```

> **CAPTURA**: salida de `dig` (sección `ANSWER`) y de `nslookup`.

## 7. Tareas de ampliación

### 7.1 Registro CNAME

Alias `web.maximo.test` → `debian.maximo.test`.

```bash
dig @192.168.56.10 web.maximo.test CNAME +short
nslookup -type=cname web.maximo.test 192.168.56.10
```

> **CAPTURA**: salida de ambos comandos.

### 7.2 Registro TXT

```bash
dig @192.168.56.10 maximo.test TXT +short
nslookup -type=txt maximo.test 192.168.56.10
```

> **CAPTURA**: salida de ambos comandos.

### 7.3 Registro PTR

```bash
dig @192.168.56.10 -x 192.168.56.10 +short
nslookup 192.168.56.10 192.168.56.10
```

> **CAPTURA**: salida de ambos comandos.

### 7.4 Flag `aa` (Authoritative Answer)

```bash
dig @192.168.56.10 debian.maximo.test
dig @192.168.56.10 www.google.es
```

> **CAPTURA**: en la primera consulta, `flags:` incluye `aa`; en la segunda no.

El flag `aa` aparece con nuestro dominio porque el servidor es autoritativo
para esa zona, y no aparece con `www.google.es` porque la respuesta se obtiene
resolviendo recursivamente, sin ser el servidor autoritativo de ese dominio.

### 7.5 Script de autocomprobación

El fichero [`test.sh`](../test.sh) valida la sintaxis y las resoluciones. Se ejecuta
automáticamente en la última provisión de Vagrant (`config/test.sh`).

> **CAPTURA**: salida de `test.sh` con los `[OK]`.

## 8. Servidor secundario

### 8.1 Segunda máquina

Definida en el `Vagrantfile` con IP `192.168.56.11`.

### 8.2 Transferencias en el primario

En `named.conf.local` del primario se añade `allow-transfer { 192.168.56.11; };` en cada zona.

### 8.3 Configuración del secundario

- `named.conf.options`: [`files/secundario/named.conf.options`](../files/secundario/named.conf.options)
- `named.conf.local` (zonas `slave`): [`files/secundario/named.conf.local`](../files/secundario/named.conf.local)

Los ficheros de zona no se crean en el secundario: los transfiere el primario.

### 8.4 Comprobación de la transferencia

```bash
sudo journalctl -u named --since "10 minutes ago"
```

> **CAPTURA**: log del secundario con la transferencia correcta.

```bash
dig @192.168.56.11 maximo.test SOA +norecurse
dig @192.168.56.11 debian.maximo.test A +short
dig @192.168.56.11 -x 192.168.56.10 +short
dig @192.168.56.10 maximo.test SOA +short
dig @192.168.56.11 maximo.test SOA +short
```

> **CAPTURA**: consultas al secundario y comparación del serial entre ambos.

## 9. Despliegue automático con Vagrant

El despliegue completo se hace con `vagrant up`:

| Script | Función |
|--------|---------|
| `config/primario.sh` | Instala BIND, copia configuración y zonas, reinicia el servicio |
| `config/secundario.sh` | Instala BIND y configura las zonas esclavas |
| `config/test.sh` | Lanza `/vagrant/test.sh` |

> **CAPTURA**: `vagrant destroy -f` y `vagrant up` terminando sin errores.
