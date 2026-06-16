variable "proxmox_url"          { type = string,  default = "https://10.0.10.10:8006/api2/json" }
variable "proxmox_node"         { type = string,  default = "pve1" }
variable "proxmox_token_id"     { type = string,  default = "terraform@pve!provider" }
variable "proxmox_token_secret" { type = string,  sensitive = true }
variable "local:iso/debian-13.5.0-amd64-netinst.iso"             { type = string }   # local:iso/debian-12.x.0-amd64-netinst.iso
variable "build_username"       { type = string,  default = "debian" }
variable "build_password"       { type = string,  sensitive = true }
