variable "incus" {
  type = object({
    project_name      = string
    network_name      = string
    network_zone_name = string
    project_config    = optional(map(string), {})
  })
}

variable "kubernetes" {
  type = object({
    cluster = object({
      name     = string
      alias    = string
      env      = string
      endpoint = string
    })
    topology = object({
      region  = string
      zone    = string
      targets = list(string)
    })
    nodes = map(object({
      count       = optional(number, 1)
      type        = optional(string, "worker")
      group       = optional(string)
      cpu         = optional(number, 2)
      memory      = optional(string, "4GiB")
      labels      = optional(map(string), {})
      annotations = optional(map(string), {})
      taints      = optional(map(string), {})
      disks = optional(map(object({
        pool = string
        size = string
      })), {})
    }))
  })
}

variable "talos" {
  type = object({
    version         = string
    image_schematic = optional(any, {})
  })
}

variable "debug" {
  type = object({
    kubeconfig  = optional(bool, false)
    talosconfig = optional(bool, false)
  })
  default = {}
}
