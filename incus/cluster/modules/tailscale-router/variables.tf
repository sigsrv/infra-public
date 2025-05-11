variable "name" {
  type     = string
  nullable = false
}

variable "network" {
  type = object({
    parent    = optional(string)
    ipv4_cidr = string
    zone      = string
  })
}
