# =============================================================================
# portfolio-dmz.tf — VM DMZ (VLAN 40) pour le portfolio public
# =============================================================================
# Héberge nginx (site statique Docusaurus) + cloudflared (connecteur du tunnel
# "portfolio-homelab"). Le connecteur n'atteint QUE le nginx local : la VM est
# isolée du VLAN 30, donc le point d'entrée public ne peut pas pivoter vers la
# production.
# =============================================================================

resource "proxmox_virtual_environment_vm" "portfolio_dmz" {
  name        = "portfolio-dmz"
  description = "DMZ VLAN 40 - portfolio public (nginx + cloudflared), isolee du VLAN 30"
  tags        = ["opentofu", "dmz", "portfolio", "debian-13"]
  node_name   = var.proxmox_node
  vm_id       = 111

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
    vlan_id = 40
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "10.0.40.20/24"
        gateway = "10.0.40.1"
      }
    }

    dns {
      servers = ["10.0.40.1"]
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

output "portfolio_dmz_ipv4" {
  description = "IP rapportee par l'agent QEMU (VM DMZ portfolio)"
  value       = proxmox_virtual_environment_vm.portfolio_dmz.ipv4_addresses
}
