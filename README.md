# DNS Server Step by Step

Author: Maximo (GitHub: [maximo-sf](https://github.com/maximo-sf))

This document describes, step by step, how a primary and a secondary DNS server
were configured with **BIND9** on **Debian 12**, deployed automatically with
**Vagrant** and **VirtualBox**.

## Table of contents

1. [Introduction](#1-introduction)
2. [Environment](#2-environment)
3. [Creating the virtual machine](#3-creating-the-virtual-machine)
4. [Installing BIND9](#4-installing-bind9)
5. [Configuring the primary server](#5-configuring-the-primary-server)
6. [Verification with dig and nslookup](#6-verification-with-dig-and-nslookup)
7. [Extension tasks](#7-extension-tasks)
8. [Secondary server](#8-secondary-server)
9. [Automated deployment with Vagrant](#9-automated-deployment-with-vagrant)
10. [Problems found](#10-problems-found)

## 1. Introduction

The DNS (Domain Name System) is a **hierarchical** naming system. The root (`.`)
delegates to top-level domains (`.es`, `.com`, `.test`...), which in turn delegate
to second-level domains and subdomains. A fully qualified domain name (FQDN) is
read from right to left, for example `debian.maximo.test.`

Concepts used in this project:

- **Zone**: the part of the namespace managed by a server. There is a **forward** zone (name → IP) and a **reverse** zone (IP → name).
- **Primary (master) server**: holds the original zone files.
- **Secondary (slave) server**: receives a copy of the zones through a zone transfer.
- **Records**: `SOA` (zone authority data), `NS` (name servers), `A` (name → IPv4), `CNAME` (alias), `TXT` (text) and `PTR` (IP → name).

## 2. Environment

| Item | Value |
|------|-------|
| Host | Windows |
| Virtualization | VirtualBox + Vagrant |
| Guest system | Debian 12 (`debian/bookworm64`) |
| Domain | `maximo.test` |
| Private network | `192.168.56.0/24` |
| Primary server | `192.168.56.10` (`debian`) |
| Secondary server | `192.168.56.11` (`debian2`) |

Repository structure:

| Path | Content |
|------|---------|
| `Vagrantfile` | Definition of both virtual machines and their provisioning |
| `config/` | Provisioning scripts (`primary.sh`, `secundary.sh`, `test.sh`) |
| `files/primary/` | Configuration and zone files of the primary server |
| `files/secundary/` | Configuration files of the secondary server |
| `test.sh` | Self-check script |
| `doc/` | This documentation and the screenshots (`doc/img/`) |

## 3. Creating the virtual machine

The primary server is created and provisioned with a single command:

```powershell
vagrant up primary
```

Vagrant downloads the Debian image, creates the VM with the private IP
`192.168.56.10`, runs `config/primary.sh` (installs and configures BIND) and,
as the last provisioner, runs `config/test.sh`, which launches the self-check
script. The result shows the three `OK` checks and the answers to the `dig` queries:

![Primary server deployment with vagrant](img/01-vagrant-up.png)

## 4. Installing BIND9

The packages are installed from the official Debian repositories:

```bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc dnsutils
```

- `bind9`: the DNS server (`named`).
- `bind9utils`: checking tools (`named-checkconf`, `named-checkzone`).
- `bind9-doc`: documentation.
- `dnsutils`: client tools (`dig`, `nslookup`).

> **SCREENSHOT**: BIND version (`named -v`).

## 5. Configuring the primary server

### 5.1 IPv4 only (`/etc/default/named`)

```
OPTIONS="-u bind -4"
```

This tells `named` to run as the `bind` user and to use IPv4 only.

### 5.2 `named.conf.options`

Final content: [`files/primary/named.conf.options`](../files/primary/named.conf.options).

Main options:

- `acl confiables`: only these hosts (localhost and `192.168.56.0/24`) can make recursive queries.
- `allow-transfer { none; }`: zone transfers are denied by default (they are allowed per zone later).
- `listen-on port 53`: listens on localhost and on the private IP of the server.
- `recursion yes` + `allow-recursion { confiables; }`: recursion only for the trusted ACL.
- `dnssec-validation auto`: DNSSEC validation enabled.
- `listen-on-v6` commented out: IPv6 queries are not answered.

Configuration check and service status:

```bash
named-checkconf /etc/bind/named.conf.options
sudo systemctl status named
```

> **SCREENSHOT**: `named-checkconf` without errors and `systemctl status named` showing `active (running)`.

### 5.3 `named.conf.local`

Both zones are declared as `master`, and the secondary server is authorized to
receive transfers. See [`files/primary/named.conf.local`](../files/primary/named.conf.local).

### 5.4 Forward zone

File `/var/lib/bind/maximo.test.dns`, see
[`files/primary/maximo.test.dns`](../files/primary/maximo.test.dns).

### 5.5 Reverse zone

File `/var/lib/bind/maximo.test.rev`, see
[`files/primary/maximo.test.rev`](../files/primary/maximo.test.rev).

### 5.6 Checking the zones

```bash
named-checkzone maximo.test /var/lib/bind/maximo.test.dns
named-checkzone 56.168.192.in-addr.arpa /var/lib/bind/maximo.test.rev
sudo journalctl -u named --no-pager | grep "loaded serial"
```

> **SCREENSHOT**: both zones reporting `OK` and the log lines with `loaded serial`.

## 6. Verification with dig and nslookup

```bash
dig @192.168.56.10 debian.maximo.test
nslookup debian.maximo.test 192.168.56.10
```

> **SCREENSHOT**: `dig` output (`ANSWER SECTION` with `192.168.56.10`) and `nslookup` output.

## 7. Extension tasks

### 7.1 CNAME record

The alias `web.maximo.test` points to the canonical name `debian.maximo.test`.

```bash
dig @192.168.56.10 web.maximo.test CNAME +short
nslookup -type=cname web.maximo.test 192.168.56.10
```

> **SCREENSHOT**: output of both commands.

### 7.2 TXT record

A `TXT` record in the zone root contains the GitHub username.

```bash
dig @192.168.56.10 maximo.test TXT +short
nslookup -type=txt maximo.test 192.168.56.10
```

> **SCREENSHOT**: output of both commands.

### 7.3 PTR record (reverse resolution)

The IP of the server resolves to its FQDN.

```bash
dig @192.168.56.10 -x 192.168.56.10 +short
nslookup 192.168.56.10 192.168.56.10
```

> **SCREENSHOT**: output of both commands.

### 7.4 Authority check (`aa` flag)

```bash
dig @192.168.56.10 debian.maximo.test
dig @192.168.56.10 www.google.es
```

> **SCREENSHOT**: the `aa` flag in the `flags:` line of the first query and its absence in the second.

The `aa` flag appears for our domain because the server is authoritative for
that zone, and it does not appear for `www.google.es` because that answer is
obtained recursively from other servers.

### 7.5 Self-check script

The [`test.sh`](../test.sh) script validates the syntax of the configuration and
zone files and checks name resolution with `dig` against `127.0.0.1`. It runs
automatically as the last Vagrant provisioner (`config/test.sh`).

> **SCREENSHOT**: `test.sh` output with the `OK` checks.

## 8. Secondary server

### 8.1 Second virtual machine

It is defined in the `Vagrantfile` with the IP `192.168.56.11` and is started with:

```powershell
vagrant up secundary
```

### 8.2 Allowing transfers on the primary

In `named.conf.local` of the primary, each zone includes
`allow-transfer { 192.168.56.11; };`, so only the secondary server can receive
the zones.

### 8.3 Configuring the secondary

- `named.conf.options`: [`files/secundary/named.conf.options`](../files/secundary/named.conf.options)
- `named.conf.local` (slave zones): [`files/secundary/named.conf.local`](../files/secundary/named.conf.local)

The zone files are **not** created on the secondary: the primary transfers them
and BIND stores them in `/var/cache/bind/`.

### 8.4 Checking the transfer

```bash
sudo journalctl -u named --since "10 minutes ago"
```

> **SCREENSHOT**: secondary server log showing the successful transfer.

```bash
dig @192.168.56.11 maximo.test SOA +norecurse
dig @192.168.56.11 debian.maximo.test A +short
dig @192.168.56.11 -x 192.168.56.10 +short
dig @192.168.56.10 maximo.test SOA +short
dig @192.168.56.11 maximo.test SOA +short
```

> **SCREENSHOT**: queries to the secondary and comparison of the serial number on both servers.

## 9. Automated deployment with Vagrant

The whole environment is deployed with `vagrant up`:

| Script | Function |
|--------|----------|
| `config/primary.sh` | Installs BIND, copies the configuration and zone files, restarts the service |
| `config/secundary.sh` | Installs BIND and configures the slave zones |
| `config/test.sh` | Runs `/vagrant/test.sh` |

To check that everything works from scratch:

```powershell
vagrant destroy -f
vagrant up
```

> **SCREENSHOT**: `vagrant up` finishing without errors.

## 10. Problems found

| Problem | Cause | Solution |
|---------|-------|----------|
| `path for shell provisioner does not exist` | The script names (`primary.sh`, `secundary.sh`) did not match the paths written in the `Vagrantfile` | Made the paths in the `Vagrantfile` and in the scripts match the real file names |
| `bash: /vagrant/test.sh: No such file or directory` | The file was named `test-sh` instead of `test.sh` | Renamed it with `git mv test-sh test.sh` |
| `dig: Invalid option: +short` | `test.sh` had Windows line endings (CRLF), so Linux saw an invisible `\r` after each option | Converted the scripts to LF and added a `.gitattributes` rule (`*.sh text eol=lf`) |
| `communications error to ::1#53: connection refused` | `dig @localhost` tries IPv6 first, and BIND only listens on IPv4 | Used `@127.0.0.1` in `test.sh` |
| `GH007: Your push would publish a private email address` | The commit used my real email while GitHub email privacy was enabled | Configured the GitHub `noreply` email in Git and recreated the commit |
| `Can't push refs to remote. Try running "Pull" first` | The remote had commits that were not in the local repository | Synchronized the local repository with `git pull` before pushing |
