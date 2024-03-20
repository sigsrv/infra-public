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

variable "k3s_cluster_name" {
  type = string
}

variable "k3s_master_count" {
  type    = number
  default = 3
}

variable "k3s_worker_count" {
  type    = number
  default = 5
}
