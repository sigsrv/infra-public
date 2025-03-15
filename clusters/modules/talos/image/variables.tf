variable "incus" {
  type = object({
    project_name = string
  })
}

variable "talos" {
  type = object({
    version         = string
    image_schematic = optional(any, {})
  })
}
