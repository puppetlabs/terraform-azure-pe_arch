output "lb_dns_name" {
  value       = var.has_lb ? try(azurerm_public_ip.pe_compiler_lb[0].fqdn, "") : tolist(var.instances)[0].public_dns
  description = "The DNS name of either the load balancer fronting the compiler pool or the primary master, depending on architecture"
}
