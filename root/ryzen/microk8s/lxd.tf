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
  name        = "sigsrv-microk8s"
  description = "sigsrv-microk8s"

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
  ipv4_address = "10.100.0.0/16"
  ipv6_address = "fdec:100::0/64"

  ipv4_1_address = "10.100.0.1/16"
  ipv6_1_address = "fdec:100::1/64"
}

resource "lxd_network" "this" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = "sigsrv-microk8s"

  config = {
    "dns.domain"   = "microk8s.sigsrv.local"
    "ipv4.address" = local.ipv4_1_address
    "ipv4.nat"     = "true"
    "ipv6.address" = local.ipv6_1_address
    "ipv6.nat"     = "true"
  }
}

resource "lxd_profile" "default" {
  project     = lxd_project.this.name
  name        = lxd_project.this.name
  description = "sigsrv-microk8s"

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

resource "lxd_instance" "tailscale" {
  count   = 1
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-tailscale"
  image   = lxd_cached_image.ubuntu_jammy_container.fingerprint
  type    = "container"

  profiles = [
    lxd_profile.default.name,
  ]

  limits = {
    cpu    = 2
    memory = "2GiB"
  }

  config = {
    "cloud-init.user-data" = format("#cloud-config\n%s", yamlencode(
      {
        "runcmd" = [
          ["sh", "-c", "curl -fsSL https://tailscale.com/install.sh | sh"],
          [
            "sh", "-c",
            "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf"
          ],
          [
            "tailscale",
            "up",
            "--advertise-routes=${local.ipv4_address},${local.ipv6_address}",
            "--advertise-tags=tag:sigsrv-microk8s"
          ],
        ],
      }
    ))
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      # device,
    ]
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
  ]

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

  config = {
    "cloud-init.user-data" = format("#cloud-config\n%s", yamlencode(
      {
        "snap" = {
          "commands" = [
            "snap install microk8s --classic",
          ]
        }
      }
    ))
  }

  device {
    name = "nfs"
    type = "disk"
    properties = {
      pool   = local.lxd_storage_pool.default.name
      path   = "/var/sigsrv-microk8s-storage"
      source = lxd_volume.storage.name
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      # device,
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
  ]

  limits = {
    cpu    = 4
    memory = "8GiB"
  }

  config = {
    "cloud-init.user-data" = format("#cloud-config\n%s", yamlencode(
      {
        "snap" = {
          "commands" = [
            "snap install microk8s --classic",
          ],
        }
      }
    ))
  }

  device {
    name = "nfs"
    type = "disk"
    properties = {
      pool   = local.lxd_storage_pool.default.name
      path   = "/var/sigsrv-microk8s-storage"
      source = lxd_volume.storage.name
    }
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      # device,
    ]
  }
}

resource "lxd_volume" "storage" {
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-storage"
  pool    = local.lxd_storage_pool.default.name
  config = {
    size = "100GiB"
  }
}

#resource "lxd_instance" "nfs" {
#  count   = 1
#  project = lxd_project.this.name
#  name    = "${lxd_project.this.name}-nfs-${count.index}"
#  image   = lxd_cached_image.ubuntu_jammy_vm.fingerprint
#  type    = "virtual-machine"
#
#  profiles = [
#    lxd_profile.default.name,
#  ]
#
#  limits = {
#    cpu    = 2
#    memory = "4GiB"
#  }
#
#  config = {
#    "cloud-init.user-data" = format("#cloud-config\n%s", yamlencode(
#      {
#        "snap" = {
#          "commands" = [
#            "snap install microk8s --classic",
#          ],
#        }
#      }
#    ))
#  }
#
#
#
#  lifecycle {
#    ignore_changes = [
#      image,
#      config["cloud-init.user-data"],
#      # device,
#    ]
#  }
#}

