
# Variables

variable "proxmox_url" {
  type = string
  default = ""
}

variable "proxmox_host" {
  type = string
}

variable "os" {
  type    = string
  default = "win11"
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

variable "iso_checksum" {
  type    = string
  default = "sha256:2866105ea8905101f47e2d9b36c5533e0d8c3af9519e4342eddbdae755921dd7"
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "vm_cpu_cores" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "60G"
}

variable "vm_memory" {
  type    = string
  default = "8192"
}

variable "vm_name" {
  type    = string
  default = "winsrv2025-x64-hardened-template"
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type      = string
  default   = "MyStr0ng!Pass"
}

locals {
  template_description = "Windows Server 2025 64-bit template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => ${var.winrm_username}:${var.winrm_password}"
}

# --- Source ---

source "proxmox-iso" "winsrv2025-x64-hardened" {
  additional_iso_files {
    device           = "sata3"
    iso_storage_pool = "${var.iso_storage_pool}"
    unmount          = true
    cd_label         = "PROVISION"
    cd_files = [
      "iso/setup-for-ansible.ps1",
      "iso/win-updates.ps1",
      "iso/windows-common-setup.ps1",
      "http/Autounattend.xml",
    ]
  }

  additional_iso_files {
    device           = "sata4"
    iso_checksum     = "sha256:c88a0dde34605eaee6cf889f3e2a0c2af3caeb91b5df45a125ca4f701acbbbe0"
    iso_url          = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.229-1/virtio-win-0.1.229.iso"
    iso_storage_pool = "${var.iso_storage_pool}"
    unmount          = true
  }

  communicator    = "winrm"
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
  iso_file                 = "data:iso/win2025-server-x64.iso"
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
  winrm_insecure       = true
  winrm_password       = "${var.winrm_password}"
  winrm_use_ssl        = true
  winrm_username       = "${var.winrm_username}"
  unmount_iso          = true
  winrm_timeout        = "6h" // Sometimes the boot and/or updates can be really really slow
  task_timeout         = "20m" // On slow disks the imgcopy operation takes > 1m
}

# --- Build ---
build {
  sources = ["source.proxmox-iso.winsrv2025-x64-hardened"]

  provisioner "windows-shell" {
    scripts = ["scripts/disablewinupdate.bat"]
  }

  provisioner "powershell" {
    scripts = ["scripts/disable-hibernate.ps1"]
  }

  provisioner "powershell" {
    scripts = ["scripts/install-virtio-drivers.ps1"]
  }

  # Activate Windows
  provisioner "powershell" {
    inline = [
      "& ([ScriptBlock]::Create((irm https://get.activated.win))) /TSforge /Z-Windows",
    ]
  }

  # Apply baseline hardening (OSConfig)
  provisioner "powershell" {
    inline = [
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false",
      "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted",
      "Install-Module -Name Microsoft.OSConfig -Scope AllUsers -Repository PSGallery -Force -Confirm:$false",
      "Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WS2025/WorkgroupMember -Default",
      "Set-OSConfigDesiredConfiguration -Scenario Defender/Antivirus -Default",
    ]
  }
}
