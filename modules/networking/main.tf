# To contain each PE deployment, a fresh VPC to deploy into
locals {
  name_tag = {
    Name = "pe-${var.resourcegroup.name}-${var.id}"
  }
}

# You can make subnets via the virtual network but if you create subnet resources
# terraform is unable to track the two and can / will create clashes so it will be clearer
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
# then creates separate security rule resource terraform is unable 
# to track the two and will create clashes so I will use seperate rules
resource "azurerm_network_security_group" "pe_nsg" {
  name                = "pe-${var.id}"
  location            = var.region
  resource_group_name = var.resourcegroup.name
  tags = local.name_tag
}

resource "azurerm_subnet_network_security_group_association" "pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.examplpe_subnet.id
  network_security_group_id = azurerm_network_security_group.pe_nsg.id
}

resource "azurerm_network_security_rule" "pe_ingressrule" {
    name                         = "General ingress rule"
    count                        = length(var.allow) >= 1 ? 1 : 0
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = var.allow
    destination_address_prefix   = "*"
    resource_group_name          = var.resourcegroup.name
    network_security_group_name  = azurerm_network_security_group.pe_nsg.name
  }
