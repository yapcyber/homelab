variable "state_passphrase" {
  description = "Passphrase de chiffrement du state (via TF_VAR_state_passphrase)"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  type    = string
  default = "https://10.0.10.10:8006/"
}

variable "proxmox_token_id" {
  type    = string
  default = "terraform@pve!provider"
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve1"
}

variable "template_id" {
  description = "VMID du template doré à cloner"
  type        = number
  default     = 9000
}

variable "ssh_public_key_path" {
  description = "Clé publique SSH injectée via cloud-init"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
