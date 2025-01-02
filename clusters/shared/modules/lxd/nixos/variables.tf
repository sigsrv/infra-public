variable "lxd_remote_name" {
  type = string
}

variable "lxd_project_name" {
  type = string
}

variable "lxd_instance_name" {
  type = string
}

variable "lxd_dns_servers" {
  type = list(string)
}

variable "lxd_dns_domain" {
  type = string
}

variable "nixos_config" {
  type = map(string)
}
