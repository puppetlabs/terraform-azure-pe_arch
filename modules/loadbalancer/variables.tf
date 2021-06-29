# These are the variables required for the loadbalancer submodule to function
# properly and are duplicated highly from the main module but instead do not
# have any defaults set because this submodule should never by called from
# anything else expect the main module where values for all these variables will
# always be passed i
variable ports {
    description = "A list of ports that will be load balanced"
    type        = list(string)
}
variable "region" {
  description = "Azure region that'll be targeted for infrastructure deployment"
  type        = string
}
variable primary_ip {
    description = "Primary ip used to discovery fqdn of primary if LB isn't used"
}
variable "id" {
  description = "Randomly generated value used to produce unique names for everything to prevent collisions and visually link resources together"
  type        = string
}
variable "has_lb" {
  description = "A boolean that indicates if the deployment requires load balancer deployment"
  type        = bool
}
variable virtual_network_id {
    description = "Azure virtual networks that are created by the networking module"
}
variable project {
  description = "Project string to differentiate and associate resources"
}

variable resourcegroup {
  description = "Resource group for network resources"
}

variable compiler_count {
  description = "Number of compilers created"
}

variable compiler_nics {
  description = "List of compilers nics"
}