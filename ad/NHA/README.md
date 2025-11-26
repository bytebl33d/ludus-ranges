# NINJA HACKER ACADEMY
NHA is written as a training challenge. You should find your way in to get domain admin on the 2 domains (`academy.ninja.lan` and `ninja.hack`)

- Starting point is on srv01: 10.5.10.32
- Flags are disposed on each machine, try to grab all. 
- Be careful all the machines are up to date with defender enabled.

The ansible playbooks are rewritten to support Windows Server 2025.

## Setup

```bash
$ git clone http://192.168.128.11:3000/serpent/ludus-ranges
$ cd ludus-ranges/NHA
```

### (Optionally) Create a new user

```
$ ludus user add --name Ninja --userid NHA --url https://127.0.0.1:8081
```

### Range deployment

```bash
$ ludus templates build -n win2025-server-x64-tpm-template
$ ludus templates build -n win2022-server-x64-template
$ ludus range config set -f ad/NHA/providers/ludus/config.yml --user NHA
$ ludus range deploy --user NHA
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
$ ansible-playbook -i ../ad/NHA/data/inventory -i ../workspace/inventory -i ../globalsettings.ini main.yml
```

## Connect

Optionally change the AllowedIPs to only the SRV01 host instead of the full /16 range.

```bash 
$ ludus user wireguard --user NHAc531df | tee ludus-wg.conf
[Interface]
PrivateKey = <PRIVATE_KEY>
Address = 198.51.100.5/32

[Peer]
PublicKey = <PUBLIC_KEY>
Endpoint = 192.168.128.10:51820
AllowedIPs = 10.5.0.0/16, 198.51.100.1/32
PersistentKeepalive = 25

# locally
$ wg-quick up ./ludus-wg.conf
```
