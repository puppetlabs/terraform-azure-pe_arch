# To contain each PE deployment, a fresh VPC to deploy into
locals {
  name_tag = {
    Name = "pe-${var.resourcegroup.name}-${var.id}"
  }
}

# You can make subnets via the virtual network but if you create subnet resources
# teraform is unable to track the two and can / will create clashes so it will be clearer
# to create subnet resources
resource "azurerm_virtual_network" "pe" {
 name                = "pe-${var.id}"
 address_space       = ["10.138.0.0/16"]
 location            = var.region
 resource_group_name = var.resourcegroup.name
 tags                = local.name_tag
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "pe-${var.id}"
  resource_group_name  = var.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.pe.name
  address_prefixes     = ["10.138.1.0/24"]
}

# You can make security rules via the security group but if you
# then creates seperate security rule resource teraform is unable 
# to track the two and will create clashes so I will use seperate rules
resource "azurerm_network_security_group" "pe_sg" {
  name                = "pe-${var.id}"
  location            = var.region
  resource_group_name = var.resourcegroup.name
  tags = local.name_tag
}

resource "azurerm_network_security_rule" "pe_ingressrule" {
    name                         = "General ingress rule"
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "*"
    destination_address_prefixes = var.allow
    resource_group_name          = var.resourcegroup.name
    network_security_group_name  = azurerm_network_security_group.pe_sg.name
  }