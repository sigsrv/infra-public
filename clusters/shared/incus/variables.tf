variable "networks" {
  type = map(object({
    parent    = optional(string)
    ipv4_cidr = string
    zone      = string
  }))
}
