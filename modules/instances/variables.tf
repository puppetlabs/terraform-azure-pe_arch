# These are the variables required for the instances submodule to function
# properly and are duplicated highly from the main module but instead do not
# have any defaults set because this submodule should never by called from
# anything else expect the main module where values for all these variables will
# always be passed in
variable "user" {
  description = "Instance user name that will used for SSH operations"
  type        = string
}
variable "ssh_key" {
  description = "Location on disk of the SSH public key to be used for instance SSH access"
  type        = string
}

variable "windows_user" {
  description = "Instance user name that will used for WINRM operations"
  type        = string
}
variable "windows_password" {
  description = "Password to be used for instance WINRM access"
  type        = string
  sensitive   = true
}

variable "compiler_count" {
  description = "The quantity of compilers that are deployed behind a load balancer and will be spread across defined zones"
  type        = number
}
variable "server_count" {
  description = "The quantity of nodes that are deployed within the environment for testing"
  type        = number
}
variable "database_count" {
  description = "The quantity of nodes that are deployed within the environment for testing"
  type        = number
}
variable "id" {
  description = "Randomly generated value used to produce unique names for everything to prevent collisions and visually link resources together"
  type        = string
}
variable "virtual_network_id" {
  description = "ID of virtual network provisioned by the networking submodule"
}
variable "subnet_id" {
  description = "List of subnet ID provisioned by the networking submodule"
}
variable "project" {
  description = "Name of project largely used for naming and tagging"
  type        = string
}
variable "resource_group" {
  description = "Name of resource group to contain resources"
}
variable "image_id" {
  description = "The custom image ID to use for deploying new cloud instances"
}
variable "image_offer" {
  description = "The Marketplace image offer to use when deploying new cloud instances"
  type        = string
}
variable "image_publisher" {
  description = "The Marketplace image publisher to deploy from for new cloud instances"
  type        = string
}
variable "image_version" {
  description = "The Marketplace image version to deploy from for new cloud instances"
  type        = string
}
variable "image_sku" {
  description = "The Marketplace sku to use when deploying new cloud instances"
  type        = string
}
variable "plan_name" {
  description = "The Marketplace image plan name"
}
variable "plan_product" {
  description = "The Marketplace image product name"
  type        = string
}
variable "plan_publisher" {
  description = "The Marketplace image publisher name"
  type        = string
}
variable "node_count" {
  description = "The quantity of nodes that are deployed within the environment for testing"
  type        = number
}

variable "windows_image_id" {
  description = "The custom image ID to use for deploying new cloud instances"
}
variable "windows_image_offer" {
  description = "The Marketplace image offer to use when deploying new cloud instances"
  type        = string
}
variable "windows_image_publisher" {
  description = "The Marketplace image publisher to deploy from for new cloud instances"
  type        = string
}
variable "windows_image_version" {
  description = "The Marketplace image version to deploy from for new cloud instances"
  type        = string
}
variable "windows_image_sku" {
  description = "The Marketplace sku to use when deploying new cloud instances"
  type        = string
}
variable "windows_plan_name" {
  description = "The Marketplace image plan name"
}
variable "windows_plan_product" {
  description = "The Marketplace image product name"
  type        = string
}
variable "windows_plan_publisher" {
  description = "The Marketplace image publisher name"
  type        = string
}
variable "windows_node_count" {
  description = "The quantity of windows nodes that are deployed within the environment for testing"
  type        = number
}

variable "tags" {
  description = "A set of tags that will be assigned to resources along with required"
  type        = map
}
variable "region" {
  description = "Region to create instances in"
  type        = string
}
variable "domain_name" {
  description = "Custom domain to use for internalDNS"
  type        = string
  default     = null
}