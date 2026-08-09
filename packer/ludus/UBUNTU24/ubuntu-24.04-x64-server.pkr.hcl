# Variables

variable "proxmox_url" {
  type = string
}

variable "proxmox_host" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_storage_pool" {
  type = string
}

variable "proxmox_storage_format" {
  type = string
}

variable "proxmox_skip_tls_verify" {
  type = bool
}

variable "proxmox_pool" {
  type = string
}

variable "iso_storage_pool" {
  type = string
}

variable "ansible_home" {
  type = string
}

variable "ludus_nat_interface" {
  type = string
}

# Template variables

variable "description" {
  type    = string
  default = "Ubuntu 24.04 LTS x64 server hardened."
}

variable "icon_path" {
  type    = string
  default = "icon.png"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
}

variable "os" {
  type    = string
  default = "l26"
}

variable "iso_url" {
  type    = string
  default = "https://old-releases.ubuntu.com/releases/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
}

variable "vm_cpu_cores" {
  type    = string
  default = "1"
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}

variable "vm_memory" {
  type    = string
  default = "2048"
}

variable "vm_name" {
  type    = string
  default = "ubuntu-24.04-x64-server-hardened-template"
}

variable "ssh_password" {
  type    = string
  default = "sysadmin"
}

variable "ssh_username" {
  type    = string
  default = "MyStr0ng!Pass"
}

locals {
  template_description = "Ubuntu 24.04 Server template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => localuser:password"
}

source "proxmox-iso" "ubuntu2404-server" {
  boot_command = [
    "e<down><down><down><end><wait>",
    " autoinstall<wait>",
    " ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<wait10>",
    "<F10>"
  ]
  boot_key_interval      = "100ms"
  boot_keygroup_interval = "2s"
  http_directory         = "./http"

  communicator    = "ssh"
  cores           = "${var.vm_cpu_cores}"
  cpu_type        = "host"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size         = "${var.vm_disk_size}"
    format            = "${var.proxmox_storage_format}"
    storage_pool      = "${var.proxmox_storage_pool}"
    type              = "virtio"
    discard           = true
    io_thread         = true
  }
  pool                     = "${var.proxmox_pool}"
  insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"
  iso_checksum             = "${var.iso_checksum}"
  iso_url                  = "${var.iso_url}"
  iso_storage_pool         = "${var.iso_storage_pool}"
  memory                   = "${var.vm_memory}"
  network_adapters {
    bridge = "${var.ludus_nat_interface}"
    model  = "virtio"
  }
  node                 = "${var.proxmox_host}"
  os                   = "${var.os}"
  password             = "${var.proxmox_password}"
  proxmox_url          = "${var.proxmox_url}"
  template_description = "${local.template_description}"
  username             = "${var.proxmox_username}"
  vm_name              = "${var.vm_name}"
  ssh_password         = "${var.ssh_password}"
  ssh_username         = "${var.ssh_username}"
  ssh_wait_timeout     = "30m"
  unmount_iso          = true
  task_timeout         = "20m" // On slow disks the imgcopy operation takes > 1m
}

build {
  sources = ["source.proxmox-iso.ubuntu2404-server"]

  provisioner "ansible" {
    playbook_file = "ansible/reset-machine-id.yml"
    use_proxy     = false
    user = "${var.ssh_username}"
    extra_arguments = ["--extra-vars", "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}}"]
    ansible_env_vars = ["ANSIBLE_HOME=${var.ansible_home}", "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp", "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc", "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"]
    skip_version_check = true
  }

  provisioner "ansible" {
    playbook_file = "ansible/reset-ssh-host-keys.yml"
    use_proxy     = false
    user = "${var.ssh_username}"
    extra_arguments = ["--extra-vars", "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}}"]
    ansible_env_vars = ["ANSIBLE_HOME=${var.ansible_home}", "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp", "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc", "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"]
    skip_version_check = true
  }

  # Baseline hardening
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo systemctl enable ssh",
      "sudo systemctl start ssh",

      "sudo ln -sf /dev/null /root/.bash_history",
      "sudo ln -sf /dev/null /root/.mysql_history",
      "sudo ln -sf /dev/null /root/.viminfo",
      "sudo chown root:root /root/.bash_history",
      "sudo chown root:root /root/.mysql_history",
      "sudo chown root:root /root/.viminfo",

      "sudo ln -sf /dev/null /home/${var.ssh_username}/.bash_history",
      "sudo chown root:${var.ssh_username} /home/${var.ssh_username}/.bash_history",
    ]
  }

  # Disable automatic updates
  provisioner "shell" {
    inline = [
      "sudo systemctl disable apt-daily.timer apt-daily-upgrade.timer",
      "sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer",
    ]
  }
}
