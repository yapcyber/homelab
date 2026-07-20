# =============================================================================
# games.tf — VM "games" (VLAN 30) : héberge RomM (gestionnaire de ROMs)
# =============================================================================
# Provisionnée sur pve2. Clone le template doré PRÉ-STAGÉ sur pve2 (VMID 9001,
# copie de 9000) → aucun clone inter-nœud au moment de l'apply.
# =============================================================================

resource "proxmox_virtual_environment_vm" "games" {
  name        = "games"
  description = "VLAN 30 - RomM (gestionnaire de ROMs). Clone du template pre-stage sur pve2 (9001)."
  tags        = ["opentofu", "games", "romm", "debian-13"]
  node_name   = "pve2"
  vm_id       = 112

  stop_on_destroy = true

  clone {
    vm_id = 9001 # template doré pré-stagé sur pve2 (copie locale de 9000)
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
    dedicated = 4096
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 30
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "10.0.30.20/24"
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

output "games_ipv4" {
  description = "IP rapportee par l'agent QEMU (VM games / RomM)"
  value       = proxmox_virtual_environment_vm.games.ipv4_addresses
}
