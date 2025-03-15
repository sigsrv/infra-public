variable "talos_controlplane_nodes" {
  type = list(object({
    endpoint     = string
    ipv4_address = string
  }))
}

variable "talos_machine_secrets" {
  sensitive = true
  type = object({
    client_configuration = any
  })
}
