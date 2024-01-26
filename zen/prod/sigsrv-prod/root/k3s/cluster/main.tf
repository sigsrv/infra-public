terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
  }
}

provider "lxd" {
  remote {
    default = true
    name    = "sigsrv"
    scheme  = "https"
    address = "sigsrv"
    port    = "8443"
  }
}

module "lxd_project" {
  source = "../../../../../root/modules/lxd/project"

  lxd_project_name         = "sigsrv-prod"
  lxd_storage_pool_name    = "sigsrv-lxd"
  lxd_network_ipv4_address = "10.64.0.0/16"
  lxd_network_ipv6_address = "fdec:64::0/64"
}

module "k3s_cluster" {
  source = "../../../../../root/modules/k3s/cluster"

  lxd_project_name             = module.lxd_project.lxd_project_name
  lxd_storage_pool_name        = module.lxd_project.lxd_storage_pool_name
  lxd_profile_name             = module.lxd_project.lxd_profile_name
  lxd_ubuntu_image_fingerprint = module.lxd_project.lxd_ubuntu_image_fingerprint

  k3s_cluster_name                  = "sigsrv-prod-k3s"
  k3s_cluster_master_instance_count = 3
  k3s_cluster_worker_instance_count = 5
}
