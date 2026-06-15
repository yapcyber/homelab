variable "proxmox_url" {
  type    = string
  default = "https://10.0.10.10:8006/api2/json"
}

variable "proxmox_node" {
  type    = string
  default = "pve1"
}

variable "proxmox_token_id" {
  type    = string
  default = "terraform@pve!provider"
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "iso_file" {
  type = string
}

variable "build_username" {
  type    = string
  default = "debian"
}

variable "build_password" {
  type      = string
  sensitive = true
}
