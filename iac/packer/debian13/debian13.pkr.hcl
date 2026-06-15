source "proxmox-iso" "debian13" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  vm_id                = 9000
  vm_name              = "debian13-golden"
  template_name        = "debian13-golden"
  template_description = "Debian 13 doré (Packer) — ${timestamp()}"
  tags                 = "debian-13;template;packer"

  boot_iso {
    type     = "scsi"
    iso_file = var.iso_file
    unmount  = true
  }

  bios            = "seabios"
  cores           = 2
  memory          = 2048
  cpu_type        = "host"
  os              = "l26"
  scsi_controller = "virtio-scsi-pci"
  qemu_agent      = true
  vga { type = "std" }

  disks {
    type         = "scsi"
    storage_pool = "local-lvm"
    disk_size    = "20G"
    format       = "raw"
    discard      = true
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
    vlan_tag = "100"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.pkrtpl.cfg", { build_password = var.build_password })
  }
  boot_wait = "10s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg priority=critical <enter>"
  ]

  ssh_username           = var.build_username
  ssh_password           = var.build_password
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 25
}

build {
  name    = "debian13-golden"
  sources = ["source.proxmox-iso.debian13"]
  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    scripts         = ["scripts/provision.sh"]
  }
}
