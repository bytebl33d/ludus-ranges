# Cyber Ranges

## Description

This repo contains custom cyber ranges that serve as a Active Directory pentest environment. The purpose of these labs is to give pentesters a vulnerable Active Directory environment ready to use to practice usual attack techniques.

### Available Labs

- NHA: A lab with 5 vms and 2 domains:
  - MSSQL
  - RBCD
  - Credential Dumping
  - ADCS
  - Forest Trust Attacks

- PUPPET: A lab with 3 vms and 1 domain, where you learn to operate with the Sliver C2 framework:
  - RBCD
  - Service Hijacking
  - DACL Permissions
  - DevOps Infrastructure

- DRACARYS: A challenge with 3 vms and 1 domain.

## Ludus

### Building Templates

```bash
$ ludus templates list
+------------------------------------+-------+
|              TEMPLATE              | BUILT |
+------------------------------------+-------+
| debian-11-x64-server-template      | FALSE |
| debian-12-x64-server-template      | FALSE |
| kali-x64-desktop-template          | FALSE |
| win11-22h2-x64-enterprise-template | FALSE |
| win2022-server-x64-template        | FALSE |
+------------------------------------+-------+

$ ludus templates add -d <TEMPLATE_DIRECTORY>
$ ludus tamplates build -n win-2025-server-x64-tpm-template

# custom templates
$ ludus templates add -d packer/ludus/WINSRV2025
$ ludus templates build -n winsrv2025-x64-hardened-template
```

> [!warning]
> Custom ludus templates (see EXAMPLE range) in this repo require changing the default credentials (localuser:password) of ludus to work.
> To change these credentials, edit the `ansible/range-management/group_vars/windows.yml` and disable `sysprep` in the `ludus/config.conf`.

### Range Deployment

Create a new user for the range.

```bash
ludus users add -i LAB -n LABUSER --url https://127.0.0.1:8081
```

Set the active lab config and deploy the lab.

```bash
$ ludus range config set -f ad/EXAMPLE/providers/ludus/config.yml --user <USER>
$ ludus range deploy --user <USER>

$ ludus range status --user <USER>
+---------+---------------+------------------+---------------+-------------------+-----------------+
| USER ID | RANGE NETWORK | LAST DEPLOYMENT  | NUMBER OF VMS | DEPLOYMENT STATUS | TESTING ENABLED |
+---------+---------------+------------------+---------------+-------------------+-----------------+
|  DRAC   |  10.5.0.0/16  | 2026-08-08 13:25 |       4       |      SUCCESS      |      FALSE      |
+---------+---------------+------------------+---------------+-------------------+-----------------+
+------------+--------------------------+-------+-------------+
| PROXMOX ID |         VM NAME          | POWER |     IP      |
+------------+--------------------------+-------+-------------+
|    106     | DRAC-router-debian12-x64 |  On   | 10.5.10.254 |
|    107     | DRAC-DC01                |  On   | 10.5.10.10  |
|    108     | DRAC-SRV01               |  On   | 10.5.10.11  |
|    110     | DRAC-LX01                |  On   | 10.5.10.12  |
+------------+--------------------------+-------+-------------+
```

### Ansible Provisioning

> [!note]
> Update the `globalsettings.ini` file and replace `CHANGE_ME` with the given ludus ip range from the range deployment output (e.g. `10.5.10`). 

Example command to run the playbook for the NHA lab:

```bash
cd ansible
ansible-playbook -i ../ad/NHA/data/inventory -i ../ad/NHA/providers/ludus/inventory -i ../globalsettings.ini nha-main.yml
```

### Snapshot and start hacking

```bash
$ ludus --user <USER> snapshot create clean-setup -d "Clean range setup after ansible run"

$ ludus --user <USER> power on -n all
[INFO]  Full range power on in progress
```

## VMWare

### Packer

```bash
# Packer VMWare plugin
packer plugins install github.com/vmware/vmware
```

Change IPs and Administrator credentials or leave the default (`Administrator:MyStr0ng!Pass`).

```bash
cd packer/WINSRV2025 && packer build -var-file variables.pkrvars.hcl .
```

### Ansible Provisioning

Example command to run the playbook for the EXAMPLE lab:

```bash
cd ansible
ansible-playbook -i ../ad/EXAMPLE/data/inventory -i ../ad/EXAMPLE/providers/vmware/inventory -i ../globalsettings.ini main.yml
```
