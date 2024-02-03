variable "lxd_project_name" {
  type = string
}

variable "lxd_storage_pool_name" {
  type = string
}

variable "lxd_profile_name" {
  type = string
}

variable "lxd_ubuntu_image_fingerprint" {
  type = string
}

variable "k3s_cluster_name" {
  type = string
}

variable "k3s_cluster_master_instance_count" {
  type    = number
  default = 3
}

variable "k3s_cluster_worker_instance_count" {
  type    = number
  default = 5
}
