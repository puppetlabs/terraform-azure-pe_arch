# Output data that will be used by other submodules to build other parts of the
# stack to support defined architecture
output "console" {
  value       = try(azurerm_public_ip.server_public_ip[0].ip_address, "")
  description = "This will be the external IP address assigned to the Puppet Enterprise console"
}
output "compilers" {
  value       = var.compiler_count == 0 ? azurerm_linux_virtual_machine.server[*] : azurerm_linux_virtual_machine.compiler[*]
  description = "Depending on architecture, either the primary master or the group of compilers created by the module for use by other modules"
}
