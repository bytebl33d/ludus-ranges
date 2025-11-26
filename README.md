# Ludus Cyber Ranges
This repo contains custom ludus cyber ranges.

## Building Templates

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
```

## Range Deployment

```bash
$ ludus range config get > ludus-range-default.yml
$ ludus range config set -f ludus-range-default.yml
$ ludus range deploy --user <USER>
```

## Ansible Provisioning

```bash
$ cd ansible
$ ansible-playbook -i ../ad/NHA/data/inventory -i ../workspace/inventory -i ../globalsettings.ini main.yml
```

## Snapshot and start hacking
```
$ ludus --user <USER> snapshot create clean-setup -d "Clean range setup after ansible run"

$ ludus --user NHAc531df power on -n all
[INFO]  Full range power on in progress
```
