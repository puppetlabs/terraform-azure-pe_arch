locals {
  lb_count = var.has_lb ? 1 : 0
}

resource "azurerm_public_ip" "pe_compiler_lb_ip" {
  name                = "pe-compiler-lb-${var.id}"
  count               = local.lb_count
  location            = var.region
  resource_group_name = var.resourcegroup.name
  tags                = var.tags
  domain_name_label   = "pe-compiler-lb-${var.id}"
  allocation_method   = "Static"
}

# For simplicity i have made this a standard LB avoiding various issues such as VmIsNotInSameAvailabilitySetAsLb
# but this should be reviewed more options to allow lab setups to use basic which is free would be desirable
resource "azurerm_lb" "pe_compiler_lb" {
  name                = "pe-compiler-lb-${var.id}"
  location            = var.region
  count               = local.lb_count
  resource_group_name = var.resourcegroup.name
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "pe-compile-lb-${var.id}"
    public_ip_address_id = azurerm_public_ip.pe_compiler_lb_ip[0].id
  }
}

# This should be the api status check
# Note default number of probes for failure is 2 and interval is 5 seconds
resource "azurerm_lb_probe" "pe_compiler_lb_probe" {
  name                = "pe-compiler-lb-${var.id}"
  resource_group_name = var.resourcegroup.name
  loadbalancer_id     = azurerm_lb.pe_compiler_lb[0].id
  count               = local.lb_count
  port                = 8140
  protocol            = "tcp"
}

resource "azurerm_lb_backend_address_pool" "pe_compiler_lb_backend_pool" {
  loadbalancer_id = azurerm_lb.pe_compiler_lb[0].id
  count           = local.lb_count
  name            = "pe-compiler-lb-${var.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "pe_compiler_lb_backend_association" {
  count                   = local.lb_count >= 1 ? length(var.compiler_nics) : 0
  network_interface_id    = var.compiler_nics[count.index].id 
  ip_configuration_name   = "compiler"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pe_compiler_lb_backend_pool[0].id
}

resource "azurerm_lb_rule" "pe_compiler_lb_rule" {
  resource_group_name            = var.resourcegroup.name
  loadbalancer_id                = azurerm_lb.pe_compiler_lb[0].id
  count                          = local.lb_count >= 1 ? length(var.ports) : 0
  name                           = var.ports[count.index]
  protocol                       = "Tcp"
  backend_port                   = var.ports[count.index]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pe_compiler_lb_backend_pool[0].id
  frontend_port                  = var.ports[count.index]
  frontend_ip_configuration_name = azurerm_lb.pe_compiler_lb[0].frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.pe_compiler_lb_probe[0].id
}