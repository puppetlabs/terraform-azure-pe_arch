locals {
  name_tag = {
    Name = "pe-${var.project}-${var.id}"
  }
}

resource "azurerm_ssh_public_key" "pe_adm" {
  name   = "pe_adm_${var.project}"
  public_key = file(var.ssh_key)
  resource_group_name = var.resource_group.name
  location = var.region
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
    name                          = "internal"
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
  # this should be centos based by rogue wave
  #CentOS                                              OpenLogic                                           7_9-gen2                                            OpenLogic:CentOS:7_9-gen2:7.9.2021020401 
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  tags        = local.name_tag
  
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
#resource "aws_instance" "psql" {
#  ami                    = data.aws_ami.centos7.id
#  instance_type          = "t3.2xlarge"
  # count is used to effectively "no-op" this resource in the event that we
  # deploy any architecture other than xlarge
#  count                  = var.database_count
#  key_name               = aws_key_pair.pe_adm.key_name
#  subnet_id              = var.subnet_ids[count.index]
#  tags                   = merge(var.default_tags, tomap({Name = "pe-psql-${var.project}-${count.index}-${var.id}"}))

#  root_block_device {
#    volume_size = 100
#    volume_type = "gp2"
#  }

  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval $(ssh-agent)
  # $ ssh-add
#  provisioner "remote-exec" {
#    connection {
#      host        = self.public_ip
#      type        = "ssh"
#      user        = var.user
#    }
#    inline = ["# Connected"]
#  }
#}

# The defining difference between standard and other architectures is the
# presence of load balanced instances with the sole duty of compiling catalogs
# for agents. A user chosen number of Compilers will be deployed in large and
# extra large but only ever zero can be deployed when the operating mode is set
# to standard
#resource "aws_instance" "compiler" {
#  ami                    = data.aws_ami.centos7.id
#  instance_type          = "t3.xlarge"
  # count is used to effectively "no-op" this resource in the event that we
  # deploy the standard architecture
#  count                  = var.compiler_count
#  key_name               = aws_key_pair.pe_adm.key_name
#  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
#  tags                   = merge(var.default_tags, tomap({Name = "pe-compiler-${var.project}-${count.index}-${var.id}"}))

#    volume_size = 15
#  root_block_device {
#    volume_type = "gp2"
#  }

  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval `ssh-agent`
  # $ ssh-add
#  provisioner "remote-exec" {
#    connection {
#      host        = self.public_ip
#      type        = "ssh"
#      user        = var.user
#    }
#    inline = ["# Connected"]
#  }
#}

# User requested number of nodes to serve as agent nodes for when this module is
# used to standup Puppet Enterprise for test and evaluation
#resource "aws_instance" "node" {
#  ami                    = data.aws_ami.centos7.id
#  instance_type          = "t3.small"
#  count                  = var.node_count
#  key_name               = aws_key_pair.pe_adm.key_name
#  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
#  tags                   = merge(var.default_tags, tomap({Name = "pe-node-${var.project}-${count.index}-${var.id}"}))

#  root_block_device {
#    volume_size = 15
#    volume_type = "gp2"
#  }

  # Using remote-execs on each instance deployment to ensure things are really
  # really up before doing to the next step, helps with Bolt plans that'll
  # immediately connect then fail
  #
  # NOTE: you will need to add your private key corresponding to `ssh_key` 
  # to the ssh agent like so:
  # $ eval `ssh-agent`
  # $ ssh-add
#  provisioner "remote-exec" {
#    connection {
#      host        = self.public_ip
#      type        = "ssh"
#      user        = var.user
#    }
#    inline = ["# Connected"]
#  }
#}