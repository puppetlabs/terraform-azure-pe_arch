# Output data that will be used by other submodules to build other parts of the
# stack to support defined architecture
output "virtual_network_id" {
  value       = azurerm_virtual_network.pe.id
  description = "Virtual network id"
}

output "subnet_id" {
  value       = azurerm_subnet.pe_subnet.id
  description = "subnet id"
}