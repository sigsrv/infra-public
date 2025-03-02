variable "status" {
  default = "running"

  validation {
    condition     = contains(["ready", "running"], var.status)
    error_message = "Invalid status: ${var.status}"
  }
}

variable "incus_project_name" {
  type     = string
  nullable = false
}

variable "incus_network_name" {
  type     = string
  nullable = false
}

variable "incus_network_zone_name" {
  type     = string
  nullable = false
}

variable "incus_instance_targets" {
  type     = list(string)
  nullable = false
}

variable "incus_instance_name_prefix" {
  type     = string
  nullable = true
  default  = null
}

variable "incus_project_name_prefix" {
  type     = string
  nullable = false
  default  = "sigsrv-"
}

variable "talos_version" {
  type = string
}

variable "talos_controlplane_node_count" {
  type     = number
  nullable = false
}

variable "talos_worker_node_count" {
  type     = number
  nullable = false
}

variable "kubernetes_topology_region" {
  type     = string
  nullable = false
}

variable "kubernetes_topology_zone" {
  type     = string
  nullable = true
}
