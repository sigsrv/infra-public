variable "incus_project_name" {
  type    = string
  default = "default"
}

variable "talos_version" {
  type = string
}

variable "talos_image_schematic" {
  type    = any
  default = {}
}
