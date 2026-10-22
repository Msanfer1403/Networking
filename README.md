# Dns-step-by-step

Automated deployment of a primary and a secondary DNS server (**BIND9**) on
**Debian 12**, using **Vagrant** and **VirtualBox**.

**Author:** Maximo ([maximo-sf](https://github.com/maximo-sf))

📄 Full documentation with commands and screenshots: [`doc/README.md`](doc/README.md)

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- Virtualization enabled in the BIOS

## Usage

```bash
git clone https://github.com/maximo-sf/dns-step-by-step.git
cd dns-step-by-step
vagrant up
```

The first run takes a few minutes because it downloads the Debian image. When
provisioning finishes, the output of `test.sh` shows that the configuration and
the name resolution are correct.

Machines: `primary` (`192.168.56.10`) and `secundary` (`192.168.56.11`).

```bash
vagrant ssh primary     # log in to the primary server
vagrant ssh secundary   # log in to the secondary server
vagrant destroy -f      # delete both machines
```

## Repository structure

| Path | Content |
|------|---------|
| `Vagrantfile` | Definition of both VMs |
| `config/` | Provisioning scripts |
| `files/` | Configuration and zone files copied into the VMs |
| `test.sh` | Self-check script |
| `doc/` | Documentation and screenshots |
