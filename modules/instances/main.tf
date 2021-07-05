locals {
  name_tag = {
    Name = "pe-${var.project}-${var.id}"
  }

  av_set= var.compiler_count > 0 ? 1 : 0
}

resource "azurerm_ssh_public_key" "pe_adm" {
  name   = "pe_adm_${var.project}"
  public_key = file(var.ssh_key)
  resource_group_name = var.resource_group.name
  location = var.region
  tags = local.name_tag
}

resource "azurerm_public_ip" "server_public_ip" {
  name                = "pe-server-${var.project}-${count.index}-${var.id}"
  resource_group_name = var.resource_group.name
  location            = var.region
  count               = var.server_count
  allocation_method   = "Static"
  tags = local.name_tag
}

resource "azurerm_network_interface" "server_nic" {
  name                = "pe-server-${var.project}-${count.index}-${var.id}"
  location            = var.region
  count               = var.server_count
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = "server"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.server_public_ip[count.index].id
  }
}

# In both large and standard we only require a single Primary but under a
# standard architecture the instance will also serve catalogs as a Compiler in
# addition to hosting all other core services. 
resource "azurerm_linux_virtual_machine" "server" {
  name                   = "pe-server-${var.project}-${count.index}-${var.id}"
  count                  = var.server_count
  resource_group_name    = var.resource_group.name
  location               = var.region
  size                   = "Standard_D4_v4"
  admin_username         = var.user
  network_interface_ids  = [
    azurerm_network_interface.server_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.user
    public_key = azurerm_ssh_public_key.pe_adm.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

# Due to the nature of azure resources there is no single resource which presents in terraform both public IP and internal DNS
# for consistency with other providers I thought it would work best to put these tags on the instance
  tags        = {
    Name = "pe-${var.project}-${var.id}"
    public_ip_address = azurerm_public_ip.server_public_ip[count.index].ip_address
    internal_fqdn = "pe-server-${var.project}-${count.index}-${var.id}.${azurerm_network_interface.server_nic[count.index].internal_domain_name_suffix}"
  }
  
  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval $(ssh-agent)
  # $ ssh-add
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = var.user
    }
    inline = ["# Connected"]
  }
}

# The biggest infrastructure difference to account for between large and extra
# large is externalization of the database service. Again given out assumption
# that extra large currently also means "with replica", we deploy two identical
# hosts in extra large but nothing in the other two architectures
resource "azurerm_public_ip" "psql_public_ip" {
  name                = "pe-psql-${var.project}-${count.index}-${var.id}"
  resource_group_name = var.resource_group.name
  location            = var.region
  count               = var.database_count
  allocation_method   = "Static"
  tags = local.name_tag
}

resource "azurerm_network_interface" "psql_nic" {
  name                = "pe-psql-${var.project}-${count.index}-${var.id}"
  location            = var.region
  count               = var.database_count
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = "psql"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.psql_public_ip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "psql" {
  name                   = "pe-psql-${var.project}-${count.index}-${var.id}"
  count                  = var.database_count
  resource_group_name    = var.resource_group.name
  location               = var.region
  size                   = "Standard_D8_v4"
  admin_username         = var.user
  network_interface_ids  = [
    azurerm_network_interface.psql_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.user
    public_key = azurerm_ssh_public_key.pe_adm.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 100
  }
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

# Due to the nature of azure resources there is no single resource which presents in terraform both public IP and internal DNS
# for consistency with other providers I thought it would work best to put these tags on the instance
  tags        = {
    Name = "pe-${var.project}-${var.id}"
    public_ip_address = azurerm_public_ip.psql_public_ip[count.index].ip_address
    internal_fqdn = "pe-psql-${var.project}-${count.index}-${var.id}.${azurerm_network_interface.psql_nic[count.index].internal_domain_name_suffix}"
  }
  
  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval $(ssh-agent)
  # $ ssh-add
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = var.user
    }
    inline = ["# Connected"]
  }
}

# The defining difference between standard and other architectures is the
# presence of load balanced instances with the sole duty of compiling catalogs
# for agents. A user chosen number of Compilers will be deployed in large and
# extra large but only ever zero can be deployed when the operating mode is set
# to standard
resource "azurerm_availability_set" "compiler_availability_set" {
  name                = "pe-compiler-${var.project}-${count.index}-${var.id}"
  count               = local.av_set
  location            = var.region
  resource_group_name = var.resource_group.name
  tags = local.name_tag
}

resource "azurerm_public_ip" "compiler_public_ip" {
  name                = "pe-compiler-${var.project}-${count.index}-${var.id}"
  resource_group_name = var.resource_group.name
  location            = var.region
  count               = var.compiler_count
  allocation_method   = "Static"
  tags                = local.name_tag
}

resource "azurerm_network_interface" "compiler_nic" {
  name                = "pe-compiler-${var.project}-${count.index}-${var.id}"
  location            = var.region
  count               = var.compiler_count
  resource_group_name = var.resource_group.name
    ip_configuration {
    name                          = "compiler"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.compiler_public_ip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "compiler" {
  name                   = "pe-compiler-${var.project}-${count.index}-${var.id}"
  count                  = var.compiler_count
  resource_group_name    = var.resource_group.name
  location               = var.region
  availability_set_id    = azurerm_availability_set.compiler_availability_set[0].id
  size                   = "Standard_D4_v4"
  admin_username         = var.user
  network_interface_ids  = [
    azurerm_network_interface.compiler_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.user
    public_key = azurerm_ssh_public_key.pe_adm.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

# Due to the nature of azure resources there is no single resource which presents in terraform both public IP and internal DNS
# for consistency with other providers I thought it would work best to put these tags on the instance
    tags        = {
    Name = "pe-${var.project}-${var.id}"
    public_ip_address = azurerm_public_ip.compiler_public_ip[count.index].ip_address
    internal_fqdn = "pe-compiler-${var.project}-${count.index}-${var.id}.${azurerm_network_interface.compiler_nic[count.index].internal_domain_name_suffix}"
  }
  
  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval $(ssh-agent)
  # $ ssh-add
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = var.user
    }
    inline = ["# Connected"]
  }
}

# User requested number of nodes to serve as agent nodes for when this module is
# used to standup Puppet Enterprise for test and evaluation
resource "azurerm_public_ip" "node_public_ip" {
  name                = "pe-node-${var.project}-${count.index}-${var.id}"
  resource_group_name = var.resource_group.name
  location            = var.region
  count               = var.node_count
  allocation_method   = "Static"
  tags = local.name_tag
}

resource "azurerm_network_interface" "node_nic" {
  name                = "pe-node-${var.project}-${count.index}-${var.id}"
  location            = var.region
  count               = var.node_count
  resource_group_name = var.resource_group.name
  ip_configuration {
    name                          = "node"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node_public_ip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "node" {
  name                   = "pe-instance-${var.project}-${count.index}-${var.id}"
  count                  = var.node_count
  resource_group_name    = var.resource_group.name
  location               = var.region
  size                   = "Standard_D4_v4"
  admin_username         = var.user
  network_interface_ids  = [
    azurerm_network_interface.node_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.user
    public_key = azurerm_ssh_public_key.pe_adm.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

# Due to the nature of azure resources there is no single resource which presents in terraform both public IP and internal DNS
# for consistency with other providers I thought it would work best to put these tags on the instance
    tags        = {
    Name = "pe-${var.project}-${var.id}"
    public_ip_address = azurerm_public_ip.node_public_ip[count.index].ip_address
    internal_fqdn = "pe-instance-${var.project}-${count.index}-${var.id}.${azurerm_network_interface.node_nic[count.index].internal_domain_name_suffix}"
  }
  
  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval $(ssh-agent)
  # $ ssh-add
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = var.user
    }
    inline = ["# Connected"]
  }
}