# Terraform setup stuff, required providers, where they are sourced from, and
# the provider's configuration requirements.
terraform {
  required_providers {
    hiera5 = {
      source  = "chriskuchin/hiera5"
      version = "0.3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.64.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

# Sets the variables that'll be interpolated to determine where variables are
# located in the hierarchy
provider "hiera5" {
  scope = {
    architecture = var.architecture
    replica      = var.replica
  }
}

# GCP region and project to operating within
provider "azurerm" {
  features {}
}

# hiera lookps
data "hiera5" "server_count" {
  key = "server_count"
}
data "hiera5" "database_count" {
  key = "database_count"
}
data "hiera5_bool" "has_compilers" {
  key = "has_compilers"
}

# It is intended that multiple deployments can be launched easily without
# name collisions
resource "random_id" "deployment" {
  byte_length = 3
}

# Resource group is so central it makes sense to live in the main tf outside of modules
resource "azurerm_resource_group" "resource_group" {
  name     = var.project
  location = var.region
  tags     = local.tags
}

# Collect some repeated values used by each major component module into one to
# make them easier to update
locals {
  compiler_count          = data.hiera5_bool.has_compilers.value ? var.compiler_count : 0
  id                      = random_id.deployment.hex
  has_lb                  = data.hiera5_bool.has_compilers.value ? true : false
  image_id                = length(regexall("^/", var.instance_image)) > 0 ? var.instance_image : null
  image_list              = local.image_id == null ? split(":", var.instance_image) : null
  image_publisher         = try(local.image_list[0], null)
  image_offer             = try(local.image_list[1], null)
  image_sku               = try(local.image_list[2], null)
  image_version           = try(local.image_list[3], null)
  plan_list               = try(split(":", var.image_plan), null)
  plan_name               = try(local.plan_list[0], null)
  plan_product            = try(local.plan_list[1], null)
  plan_publisher          = try(local.plan_list[2], null)
  windows_image_id        = length(regexall("^/", var.windows_instance_image)) > 0 ? var.windows_instance_image : null
  windows_image_list      = local.windows_image_id == null ? split(":", var.windows_instance_image) : null
  windows_image_publisher = try(local.windows_image_list[0], null)
  windows_image_offer     = try(local.windows_image_list[1], null)
  windows_image_sku       = try(local.windows_image_list[2], null)
  windows_image_version   = try(local.windows_image_list[3], null)
  windows_plan_list       = try(split(":", var.windows_image_plan), null)
  windows_plan_name       = try(local.windows_plan_list[0], null)
  windows_plan_product    = try(local.windows_plan_list[1], null)
  windows_plan_publisher  = try(local.windows_plan_list[2], null)
  tags            = merge({
    description = "PEADM Deployed Puppet Enterprise"
    project     = var.project
  }, var.tags)
}

# Contain all the networking configuration in a module for readability
module "networking" {
  source        = "./modules/networking"
  id            = local.id
  resourcegroup = azurerm_resource_group.resource_group
  allow         = var.firewall_allow
  region        = var.region
  tags          = local.tags
}

# Contain all the loadbalancer configuration in a module for readability
module "loadbalancer" {
  source             = "./modules/loadbalancer"
  id                 = local.id
  ports              = ["8140", "8142"]
  region             = var.region
  primary_ip         = module.instances.primary_ip
  has_lb             = local.has_lb
  resourcegroup      = azurerm_resource_group.resource_group
  virtual_network_id = module.networking.virtual_network_id
  compiler_nics      = module.instances.compiler_nics
  compiler_count     = local.compiler_count
  tags               = local.tags
}

# Contain all the instances configuration in a module for readability
module "instances" {
  source                  = "./modules/instances"
  id                      = local.id
  virtual_network_id      = module.networking.virtual_network_id
  subnet_id               = module.networking.subnet_id
  user                    = var.user
  ssh_key                 = var.ssh_key
  compiler_count          = local.compiler_count
  node_count              = var.node_count
  windows_node_count      = var.windows_node_count 
  tags                    = local.tags
  image_id                = local.image_id
  image_publisher         = local.image_publisher
  image_offer             = local.image_offer
  image_sku               = local.image_sku
  image_version           = local.image_version
  plan_name               = local.plan_name
  plan_product            = local.plan_product
  plan_publisher          = local.plan_publisher
  windows_image_id        = local.windows_image_id
  windows_image_publisher = local.windows_image_publisher
  windows_image_offer     = local.windows_image_offer
  windows_image_sku       = local.windows_image_sku
  windows_image_version   = local.windows_image_version
  windows_plan_name       = local.windows_plan_name
  windows_plan_product    = local.windows_plan_product
  windows_plan_publisher  = local.windows_plan_publisher
  windows_password        = var.windows_password
  windows_user            = var.windows_user
  project                 = var.project
  resource_group          = azurerm_resource_group.resource_group
  region                  = var.region
  server_count            = data.hiera5.server_count.value
  database_count          = data.hiera5.database_count.value
  domain_name             = var.domain_name
}
