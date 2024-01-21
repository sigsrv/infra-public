variable "lxd_project_name" {
  type = string
}

variable "lxd_storage_pool_name" {
  type    = string
  default = "sigsrv-lxd"
}

variable "lxd_network_ipv4_address" {
  type    = string
  default = "10.64.0.0/16"
}

variable "lxd_network_ipv6_address" {
  type    = string
  default = "fdec:64::0/64"
}
