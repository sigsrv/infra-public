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

variable "kubernetes" {
  type = object({
    cluster_name    = string
    topology_region = string
    topology_zone   = string
  })
}

variable "talos_node" {
  type = object({
    type   = string
    name   = string
    target = string
    cpu    = number
    memory = string
  })
}

variable "talos_image" {
  type = any // TODO: typing this
}

variable "talos_machine_secrets" {
  sensitive = true
  type = object({
    machine_secrets      = any
    client_configuration = any
  })
}
