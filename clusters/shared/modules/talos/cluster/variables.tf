variable "incus" {
  type = object({
    project_name         = string
    project_name_prefix  = optional(string, "sigsrv-")
    network_name         = string
    network_zone_name    = string
    instance_name_prefix = optional(string)
    instance_targets     = list(string)
  })
}

variable "talos" {
  type = object({
    version = string
    controlplane_node = object({
      count  = number
      cpu    = optional(number, 2)
      memory = optional(string, "4GiB")
    })
    worker_node = object({
      count  = number
      cpu    = optional(number, 2)
      memory = optional(string, "4GiB")
    })
  })
}

variable "kubernetes" {
  type = object({
    cluster_name    = string
    cluster_alias   = string
    cluster_env     = string
    topology_region = string
    topology_zone   = string
  })
}
