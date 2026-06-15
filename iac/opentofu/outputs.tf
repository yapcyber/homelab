output "tf_test_ipv4" {
  description = "IP rapportee par l'agent QEMU"
  value       = proxmox_virtual_environment_vm.tf_test.ipv4_addresses
}

output "tf_test_vmid" {
  value = proxmox_virtual_environment_vm.tf_test.vm_id
}
