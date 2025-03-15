variable "incus" {
  type = object({
    project_name   = string
    project_config = optional(any, {})
    network_name   = string
  })
}
