terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "1.10.2"
    }
  }
}

provider "lxd" {
  lxd_remote {
    default = true
    name    = "sigsrv"
    scheme  = "https"
    address = "sigsrv"
    port    = "8443"
  }
}

locals {
  lxd_storage_pool = {
    default = {
      name = "sigsrv-lxd"
    }
  }
}

resource "lxd_project" "this" {
  name        = "sigsrv-k3s"
  description = "sigsrv-k3s"

  config = {
    "features.images"          = "true"
    "features.profiles"        = "true"
    "features.storage.buckets" = "true"
    "features.storage.volumes" = "true"
    "features.networks"        = "false"
    "features.networks.zones"  = "true"
    "limits.containers"        = "16"
    "limits.cpu"               = "32"
    "limits.disk"              = "5TiB"
    "limits.instances"         = "32"
    "limits.memory"            = "64GiB"
    "limits.networks"          = "4"
    "limits.virtual-machines"  = "16"
  }
}

resource "lxd_cached_image" "ubuntu_jammy_container" {
  source_remote = "ubuntu"
  source_image  = "jammy/amd64"
  type          = "container"
}

resource "lxd_cached_image" "ubuntu_jammy_vm" {
  source_remote = "ubuntu"
  source_image  = "jammy/amd64"
  type          = "virtual-machine"

  depends_on = [
    lxd_cached_image.ubuntu_jammy_container
  ]
}

locals {
  ipv4_address = "10.64.0.0/16"
  ipv6_address = "fdec:64::0/64"

  ipv4_1_address = "10.64.0.1/16"
  ipv6_1_address = "fdec:64::1/64"
}

resource "lxd_network" "this" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = "sigsrv-k3s"

  config = {
    "dns.domain"   = "k3s.sigsrv.local"
    "ipv4.address" = local.ipv4_1_address
    "ipv4.nat"     = "true"
    "ipv6.address" = local.ipv6_1_address
    "ipv6.nat"     = "true"
  }
}

resource "lxd_profile" "volumes" {
  project     = lxd_project.this.name
  name        = "${lxd_project.this.name}-volumes"
  description = "sigsrv-k3s"

  device {
    name = "volumes"
    type = "disk"
    properties = {
      pool   = local.lxd_storage_pool.default.name
      path   = "/mnt/volumes"
      source = lxd_volume.volumes.name
    }
  }
}

resource "lxd_profile" "default" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = "sigsrv-k3s"

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
      pool = local.lxd_storage_pool.default.name
      path = "/"
      size = "50GiB"
    }
  }
}

resource "lxd_volume" "volumes" {
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-volumes"
  pool    = local.lxd_storage_pool.default.name
  config = {
    size                 = "1TiB"
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "lxd_instance" "master" {
  count   = 3
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-master-${count.index}"
  image   = lxd_cached_image.ubuntu_jammy_vm.fingerprint
  type    = "virtual-machine"

  profiles = [
    lxd_profile.default.name,
    lxd_profile.volumes.name,
  ]

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

  config = {}

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_instance" "worker" {
  count   = 5
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-worker-${count.index}"
  image   = lxd_cached_image.ubuntu_jammy_vm.fingerprint
  type    = "virtual-machine"

  profiles = [
    lxd_profile.default.name,
    lxd_profile.volumes.name,
  ]

  limits = {
    cpu    = 4
    memory = "8GiB"
  }

  config = {}

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}
