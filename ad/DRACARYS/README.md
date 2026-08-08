# DRACARYS

- DRACARYS is written as a training challenge where GOAD was written as a lab with a maximum of vulns.
- You should find your way in to get domain admin on the domain dracarys.lab
- Starting point is on lx01 : `<IP_RANGE>.12`
- Obviously do not cheat by looking at the passwords and flags in the recipe files, the lab must start without user to full compromise. 

## Setup

```bash
git clone https://github.com/bytebl33d/cyber-ranges.git
cd cyber-ranges/DRACARYS
```

### (Optionally) Create a new user

```bash
ludus user add --name DRACARYS --userid DRAC --url https://127.0.0.1:8081
```

### Range deployment

```bash
ludus templates add -d packer/ludus/WINSRV2025
ludus templates build -n winsrv2025-x64-hardened-template
ludus templates build -n ubuntu-24.04-x64-server-template

ludus range config set -f ad/DRACARYS/providers/ludus/config.yml --user DRAC
ludus range deploy --user DRAC
```

### Ansible Provisioning

Change the workspace inventory to reflect the correct IP addresses and run the ansible playbooks:

```bash
# change inventory IPs
$ vi workspace/inventory

# install the required collections and roles
$ ansible-galaxy collection install ansible.windows
$ ansible-galaxy collection install community.general
$ ansible-galaxy collection install community.windows
$ ansible-galaxy role install geerlingguy.mysql

$ cd ansible
$ ansible-playbook -i ../ad/DRACARYS/data/inventory -i ../ad/DRACARYS/providers/ludus/inventory -i ../globalsettings.ini dracarys-main.yml
```

## Connect

```bash 
$ ludus user wireguard --user DRAC | tee ludus-wg.conf
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
