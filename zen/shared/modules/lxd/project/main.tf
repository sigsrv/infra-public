terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
  }
}

locals {
  lxd_storage_pool = {
    default = {
      name = var.lxd_storage_pool_name
    }
  }
}

resource "lxd_project" "this" {
  name        = var.lxd_project_name
  description = "${var.lxd_project_name} (managed by Terraform)"

  config = {
    "features.images"          = "true"
    "features.profiles"        = "true"
    "features.storage.buckets" = "true"
    "features.storage.volumes" = "true"
    "features.networks"        = "false"
    "features.networks.zones"  = "true"
    "limits.containers"        = "16"
    "limits.cpu"               = "32"
    "limits.disk"              = "20TiB"
    "limits.instances"         = "32"
    "limits.memory"            = "64GiB"
    "limits.networks"          = "4"
    "limits.virtual-machines"  = "16"
  }
}

resource "lxd_network" "this" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = var.lxd_project_name

  config = {
    "dns.domain"   = "${var.lxd_project_name}.lxd.local"
    "ipv4.address" = replace(var.lxd_network_ipv4_address, "0/", "1/")
    "ipv4.nat"     = "true"
    "ipv6.address" = replace(var.lxd_network_ipv6_address, "0/", "1/")
    "ipv6.nat"     = "true"
    "dns.search"   = join(",", ["1.1.1.1", "1.0.0.1"])
  }
}

resource "lxd_profile" "this" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = var.lxd_project_name

  config = {
    "cloud-init.vendor-data" = format("#cloud-config\n%s", yamlencode(
      {
        "disable_ec2_metadata" = true
        "ssh_import_id"        = ["gh:ecmaxp"]
        "ntp" = {
          "pools" = [
            "0.asia.pool.ntp.org",
            "1.asia.pool.ntp.org",
            "2.asia.pool.ntp.org",
            "3.asia.pool.ntp.org",
          ]
        }
      }
    ))
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
    "limits.cpu"         = "2"
    "limits.memory"      = "4GiB"
    "migration.stateful" = "true"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = lxd_network.this.name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      pool         = local.lxd_storage_pool.default.name
      path         = "/"
      size         = "50GiB"
      "size.state" = "4GiB"
    }
  }
}
