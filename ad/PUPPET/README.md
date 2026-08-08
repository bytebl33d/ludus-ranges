# PUPPET

Puppet is a small active directory scenario in which you start with an already running Sliver C2 beacon on an internal system. It is designed to practice operating through a C2 framework in a modern, challenging hybrid environment.

You are tasked with performing a red team engagement on Puppet Inc. The company does not allow data leaving the internal network, so a c2 server has been set up internally and an employee executed a payload in order to simulate a successful social engineering attack.

## Setup

```bash
git clone https://github.com/bytebl33d/cyber-ranges.git
cd cyber-ranges/NHA
```

### (Optionally) Create a new user

```bash
ludus user add --name Puppet --userid PUPPET --url https://127.0.0.1:8081
```

### Range deployment

```bash
ludus templates build -n win2025-server-x64-tpm-template
ludus templates build -n win2022-server-x64-template
ludus range config set -f ad/PUPPET/providers/ludus/config.yml --user PUPPET
ludus range deploy --user PUPPET
```

### Ansible Provisioning

Change the workspace inventory to reflect the correct IP addresses and run the ansible playbooks:

```bash
# change inventory IPs
$ vi workspace/inventory

# install the required collections
$ ansible-galaxy collection install ansible.windows
$ ansible-galaxy collection install community.general
$ ansible-galaxy collection install community.windows

$ cd ansible
$ ansible-playbook -i ../ad/PUPPET/data/inventory -i ../ad/PUPPET/providers/ludus/inventory -i ../globalsettings.ini puppet-main.yml
```

## Connect

```bash 
$ ludus user wireguard --user PUPPET | tee ludus-wg.conf
[Interface]
PrivateKey = <PRIVATE_KEY>
Address = 198.51.100.5/32

[Peer]
PublicKey = <PUBLIC_KEY>
Endpoint = 192.168.20.10:51820
AllowedIPs = 10.5.0.0/16, 198.51.100.1/32
PersistentKeepalive = 25

# locally
$ wg-quick up ./ludus-wg.conf
```

Afterwards you should be able to enumerate the open FTP share to discover a sliver client and configuration file:

![Sliver C2 Setup](/docs/img/PUPPET-sliver-client.png)
