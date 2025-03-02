variable "status" {
  default = "running"

  validation {
    condition     = contains(["ready", "running"], var.status)
    error_message = "Invalid status: ${var.status}"
  }
}

variable "incus" {
  type = object({
    cluster_name         = optional(string, "sigsrv")
    project_name         = string
    network_name         = string
    network_zone_name    = string
    instance_targets     = list(string)
    instance_name_prefix = optional(string)
    project_name_prefix  = optional(string, "sigsrv-")
  })
}

variable "talos" {
  type = object({
    version                 = string
    controlplane_node_count = number
    worker_node_count       = number
  })
}

variable "kubernetes" {
  type = object({
    topology_region = string
    topology_zone   = string
  })
}
