resource "proxmox_virtual_environment_vm" "tf_test" {
  name        = "tf-test-01"
  description = "VM de test - provisionnee par OpenTofu (phase 3b)"
  tags        = ["opentofu", "test", "debian-13"]
  node_name   = var.proxmox_node
  vm_id       = 7001

  stop_on_destroy = true

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 30
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "10.0.30.50/24"
        gateway = "10.0.30.1"
      }
    }

    dns {
      servers = ["10.0.30.1"]
    }

    user_account {
      username = "debian"
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }

  # La clé SSH cloud-init force sinon un replacement à chaque plan
  lifecycle {
    ignore_changes = [
      initialization[0].user_account,
    ]
  }
}
