# Output data that will be used by other submodules to build other parts of the
# stack to support defined architecture
output "virtual_network_id" {
  value       = azurerm_virtual_network.pe.id
  description = "Virtual network id"
}

#output "subnet_ids" {
#  value       = aws_subnet.pe_subnet[*].id
#  description = "AWS subnet ids"
#}

#output "security_group_ids" {
#  value       = aws_security_group.pe_sg[*].id
#  description = "AWS security group ids"
#}