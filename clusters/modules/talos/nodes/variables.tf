variable "incus" {
  type = object({
    project_name      = string
    network_name      = string
    network_zone_name = string
  })
}

variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
    topology = object({
      region  = string
      zone    = string
      targets = list(string)
    })
  })
}

variable "node" {
  type = object({
    type        = string
    count       = number
    group       = string
    cpu         = number
    memory      = string
    labels      = map(string)
    annotations = map(string)
    taints      = map(string)
  })
}

variable "image" {
  type = any // TODO: typing this
}

variable "machine_secrets" {
  sensitive = true
  type = object({
    machine_secrets      = any
    client_configuration = any
  })
}
