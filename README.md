# Dns-step-by-step
Despliegue automático de un servidor DNS primario y uno secundario con
**BIND9** sobre **Debian 12**, usando **Vagrant** y **VirtualBox**.

**Autor:** Maximo (GitHub: [maximo-sf](https://github.com/maximo-sf))

La documentación detallada de la práctica (pasos, comandos y capturas)
está en [`doc/README.md`](doc/README.md).

## Qué hace este proyecto

- Levanta dos máquinas virtuales Debian: un servidor DNS **primario** y un **secundario**.
- Configura la zona directa `maximo.test` y la zona inversa `56.168.192.in-addr.arpa`.
- Incluye registros `A`, `NS`, `CNAME`, `TXT` y `PTR`.
- El secundario recibe las zonas del primario por transferencia de zona.
- Ejecuta un script de autocomprobación (`test.sh`) al terminar el aprovisionamiento.

## Requisitos

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Git](https://git-scm.com/)
- Virtualización activada en la BIOS

## Cómo usarlo

```bash
git clone https://github.com/maximo-sf/dns-paso-a-paso.git
cd dns-paso-a-paso
vagrant up
```

`vagrant up` crea las dos máquinas, instala y configura BIND y, al final del
primario, muestra el resultado de `test.sh`. La primera vez tarda unos minutos
porque descarga la imagen de Debian.

Para entrar en las máquinas:

```bash
vagrant ssh primario
vagrant ssh secundario
```

Para probar la resolución desde dentro de una VM:

```bash
dig @192.168.56.10 debian.maximo.test
dig @192.168.56.11 maximo.test SOA +norecurse
```

Para apagar o borrar todo:

```bash
vagrant halt        # apagar
vagrant destroy -f  # eliminar las máquinas
```

## Red

| Máquina    | Hostname | IP            | Rol         |
|------------|----------|---------------|-------------|
| primario   | debian   | 192.168.56.10 | DNS maestro |
| secundario | debian2  | 192.168.56.11 | DNS esclavo |

Red privada: `192.168.56.0/24` (la `.1` es el adaptador host-only del anfitrión).

## Estructura del repositorio

| Ruta | Contenido |
|------|-----------|
| `Vagrantfile` | Definición de las dos VMs y su aprovisionamiento |
| `config/` | Scripts de aprovisionamiento (`primario.sh`, `secundario.sh`, `test.sh`) |
| `files/primario/` | Ficheros de configuración y zonas del servidor primario |
| `files/secundario/` | Ficheros de configuración del servidor secundario |
| `test.sh` | Script de autocomprobación del servidor |
| `doc/` | Documentación en Markdown y capturas (`doc/img/`) |

## Notas

- Si cambias los registros de una zona, incrementa el número de serie SOA en el primario para que el secundario detecte el cambio.
- Los scripts deben tener saltos de línea tipo Linux (LF); el repositorio lo fuerza con `.gitattributes`.
