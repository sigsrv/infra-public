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
  source = "../../../shared/modules/lxd/project"

  lxd_remote_name          = "sigsrv"
  lxd_project_name         = "sigsrv-prod"
  lxd_storage_pool_name    = "nvme"
  lxd_network_ipv4_address = "10.64.0.0/16"
  lxd_network_ipv6_address = "fdec:64::0/64"
}

module "k3s_cluster" {
  source = "../../../shared/modules/k3s/cluster"

  lxd_remote_name       = "sigsrv"
  lxd_project_name      = module.lxd_project.lxd_project_name
  lxd_storage_pool_name = module.lxd_project.lxd_storage_pool_name
  lxd_profile_name      = module.lxd_project.lxd_profile_name
  lxd_dns_servers       = module.lxd_project.lxd_dns_servers
  lxd_dns_domain        = module.lxd_project.lxd_dns_domain
  lxd_nixos_image_alias = "nixos-unstable-vm"

  k3s_cluster_name = "sigsrv-prod"
  k3s_master_count = 3
  k3s_worker_count = 5
}
