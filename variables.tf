variable "project" {
  description = "Name of Azure resource group that will be used for grouping infrastructure"
  type        = string
}
variable "user" { 
  description = "Instance user name that will used for SSH operations"
  type        = string
}
variable "ssh_key" {
  description = "Location on disk of the SSH public key to be used for instance SSH access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
variable "region" {
  description = "Azure region that'll be targeted for infrastructure deployment"
  type        = string
  default     = "westus2"
}
variable "compiler_count" {
  description = "The quantity of compilers that are deployed behind a load balancer and will be spread across defined zones"
  type        = number
  default     = 1
}
variable "node_count" {
  description = "The quantity of nodes that are deployed within the environment for testing"
  type        = number
  default     = 0
}
variable "instance_image" {
  description = "The disk image to use when deploying new cloud instances in the form of a full length Image ID or Marketplace URN"
  type        = string
  default     = "almalinux:almalinux:8-gen2:latest"
}
variable "image_plan" {
  description = "The Marketplace offering's plan if it has one in Marketplace URN style, name:product:publisher"
  type        = string
  default     = "8-gen2:almalinux:almalinux"
}
variable "tags" {
  description = "A set of tags that will be assigned to resources along with required"
  type        = map
  default     = {}
}
variable "firewall_allow" {
  description = "List of permitted IP subnets, list most include the internal network and single addresses must be passed as a /32"
  type        = list(string)
  default     = []
}
variable "architecture" {
  description = "Which of the supported PE architectures modules to deploy xlarge, large, or standard"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "large", "xlarge"], var.architecture)
    error_message = "Architecture selection must match one of standard, large, or xlarge."
  }
}
variable "replica" {
  description = "To deploy instances required for the provisioning of a server replica"
  type        = bool
  default     = false
}
variable "destroy" {
  description = "Available to facilitate simplified destroy via Puppet Bolt, irrelevant outside specific use case"
  type        = bool
  default     = false
}