variable "status" {
  default = "running"

  validation {
    condition     = contains(["ready", "running"], var.status)
    error_message = "Invalid status: ${var.status}"
  }
}

variable "incus_project_name" {
  type = string
}

variable "incus_network_zone_name" {
  type = string
}

variable "incus_instance_name_prefix" {
  type = string
}

variable "talos_controlplane_node_count" {
  type = number
}

variable "talos_worker_node_count" {
  type = number
}

variable "talos_image" {
  type = object({
    incus_iso_volume = string
    urls = object({
      installer_secureboot = string
      iso_secureboot       = string
    })
  })
}
