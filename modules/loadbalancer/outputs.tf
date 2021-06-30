output "lb_dns_name" {
  value       = var.has_lb ? try(azurerm_public_ip.pe_compiler_lb_ip[0].fqdn, "") : var.primary_ip.fqdn
  description = "The DNS name of either the load balancer fronting the compiler pool or the primary, depending on architecture"
}
