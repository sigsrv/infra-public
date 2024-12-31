variable "lxd_remote_name" {
  type = string
}

variable "lxd_project_name" {
  type = string
}

variable "lxd_storage_pool_name" {
  type = string
}

variable "lxd_profile_name" {
  type = string
}

variable "lxd_dns_servers" {
  type = list(string)
}

variable "lxd_dns_domain" {
  type = string
}

variable "lxd_nixos_image_alias" {
  type = string
}

variable "talos_cluster_name" {
  type = string
}

variable "talos_master_config" {
  type    = map(any)
  default = {}
}

variable "talos_master_count" {
  type    = number
  default = 2
}

variable "talos_worker_count" {
  type    = number
  default = 2
}
