terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0-alpha.0"
    }
  }
}

provider "lxd" {
  //noinspection HCLUnknownBlockType
  remote {
    default = true
    name    = "sigsrv"
    address = "https://sigsrv:8443"
  }
}

provider "talos" {
  # Configuration options
}


module "lxd_project" {
  source = "../../shared/modules/lxd/project"

  lxd_remote_name          = "sigsrv"
  lxd_project_name         = "talos-dev"
  lxd_storage_pool_name    = "sigsrv-nvme"
  lxd_network_ipv4_address = "10.32.0.0/16"
  lxd_network_ipv6_address = "fdec:32::0/64"
}

# module "talos_cluster" {
#   source = "../../shared/modules/talos/cluster"

#   lxd_remote_name       = "sigsrv"
#   lxd_project_name      = module.lxd_project.lxd_project_name
#   lxd_storage_pool_name = module.lxd_project.lxd_storage_pool_name
#   lxd_profile_name      = module.lxd_project.lxd_profile_name
#   lxd_dns_servers       = module.lxd_project.lxd_dns_servers
#   lxd_dns_domain        = module.lxd_project.lxd_dns_domain
#   lxd_nixos_image_alias = ""

#   talos_cluster_name = "talos-dev"
#   talos_master_count = 1
#   talos_worker_count = 2
# }

# resource "lxd_volume" "talos" {
#   name = "talos-iso"
#   pool = "sigsrv-nvme"
#   type = "iso"

#   config = {
#     "source" = "/home/ecmaxp/talos-nocloud-amd64.iso"
#   }
# }

data "talos_image_factory_urls" "this" {
  talos_version = "v1.8.3"
  architecture  = "amd64"
  platform      = "metal"
  schematic_id  = talos_image_factory_schematic.this.id
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = "v1.8.3"
  filters = {
    names = [
      "tailscale",
    ]
  }
}

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = "example-cluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = ["10.5.0.2"]
}
