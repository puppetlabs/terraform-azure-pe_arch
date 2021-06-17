# To contain each PE deployment, a fresh VPC to deploy into
locals {
  name_tag = {
    Name = "pe-${var.project}-${var.id}"
  }
}

resource "azurerm_virtual_network" "pe" {
 cidr_block          = "10.138.0.0/16"
 location            = var.region
 resource_group_name = var.project
 tags                = local.name_tag
}

#  vpc_id = virtual_network_id.pe.id
#resource "aws_internet_gateway" "pe_gw" {

 # tags = local.name_tag
#}

#TODO implement a subnet per availability zone
#resource "aws_subnet" "pe_subnet" {
#  vpc_id            = virtual_network_id.pe.id
#  count             = length(data.aws_availability_zones.available.names)
#  availability_zone = data.aws_availability_zones.available.names[count.index]

#  cidr_block              = "10.138.${1 + count.index}.0/24"
#  map_public_ip_on_launch = true

#    Name = "pe-${var.project}-${var.id}-${data.aws_availability_zones.available.names[count.index]}"
#  tags = {
#  }

#}
#resource "aws_route_table" "pe_public" {
#  vpc_id = virtual_network_id.pe.id
#  route {
#    gateway_id = aws_internet_gateway.pe_gw.id
#    cidr_block = "0.0.0.0/0"
#  tags = local.name_tag
#  }
#}

#resource "aws_route_table_association" "pe_subnet_public" {
#  count          = length(aws_subnet.pe_subnet)
#  subnet_id      = aws_subnet.pe_subnet[count.index].id
#  route_table_id = aws_route_table.pe_public.id
#}

# Instances should not be accessible by the open internet so a fresh VPC should
# be restricted to organization allowed subnets
#resource "aws_security_group" "pe_sg" {
#  name        = "pe-${var.project}-${var.id}"
#  description = "Allow TLS inbound traffic"
#  vpc_id      = virtual_network_id.pe.id

#  ingress {
#    description = "General ingress rule"
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1" # all protocols and ports
#    cidr_blocks = var.allow

#  }
#  ingress {
#    description = "Anything from VPC"
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1" # all protocols and ports
#    cidr_blocks = tolist([virtual_network_id.pe.cidr_block])
#  }

#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  tags          = local.name_tag
#}
