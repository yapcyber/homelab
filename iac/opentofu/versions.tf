terraform {
  required_version = ">= 1.7.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.109"
    }
  }

  # Chiffrement natif du state (OpenTofu 1.7+) — passphrase via TF_VAR_state_passphrase
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }
    state {
      method   = method.aes_gcm.state_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state_method
      enforced = true
    }
  }
}
