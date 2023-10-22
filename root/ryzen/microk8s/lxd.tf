terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
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

variable "ts_authkey" {
  type      = string
  sensitive = true
}

locals {
  lxd_storage_pool = {
    default = {
      name = "default"
    }
  }
}

resource "lxd_project" "this" {
  name = "microk8s"
  config = {
    "features.images"          = "true"
    "features.profiles"        = "true"
    "features.storage.buckets" = "true"
    "features.storage.volumes" = "true"
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
}

locals {
  ipv4_address = "10.100.0.0/24"
  ipv6_address = "fd10:100:0:1::0/64"

  ipv4_1_address = "10.100.0.1/24"
  ipv6_1_address = "fd10:100:0:1::1/64"
}

resource "lxd_network" "this" {
  project = lxd_project.this.name
  name    = lxd_project.this.name

  config = {
    "ipv4.address" = local.ipv4_1_address
    "ipv4.nat"     = "true"
    "ipv6.address" = local.ipv6_1_address
    "ipv6.nat"     = "true"
  }
}

resource "lxd_profile" "base" {
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-base"

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
      size = "20GiB"
    }
  }
}

resource "lxd_instance" "tailscale" {
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-tailscale"
  image   = lxd_cached_image.ubuntu_jammy_container.fingerprint
  type    = "container"

  profiles = [
    lxd_profile.base.name,
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
          ["tailscale",
            "up",
            "--authkey=${var.ts_authkey}",
            "--advertise-routes=${local.ipv4_address},${local.ipv6_address}",
            "--advertise-tags=tag:local-sigsrv-microk8s-master"
          ],
        ],
      }
    ))
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
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
    lxd_profile.base.name,
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
        },
        "runcmd" = [
          ["sh", "-c", "curl -fsSL https://tailscale.com/install.sh | sh"],
          [
            "sh", "-c",
            "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf"
          ],
          ["tailscale",
            "up",
            "--authkey=${var.ts_authkey}",
            "--ssh",
            "--advertise-tags=tag:local-sigsrv-microk8s-master"
          ],
          ["tailscale", "down"],
        ]
      }
    ))
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
    ]
  }
}

resource "lxd_instance" "worker" {
  count   = 3
  project = lxd_project.this.name
  name    = "${lxd_project.this.name}-worker-${count.index}"
  image   = lxd_cached_image.ubuntu_jammy_vm.fingerprint
  type    = "virtual-machine"

  profiles = [
    lxd_profile.base.name,
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
        "runcmd" = [
          ["sh", "-c", "curl -fsSL https://tailscale.com/install.sh | sh"],
          [
            "sh", "-c",
            "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf"
          ],
          ["tailscale",
            "up",
            "--authkey=${var.ts_authkey}",
            "--ssh",
            "--advertise-tags=tag:local-sigsrv-microk8s-master"
          ],
          ["tailscale", "down"],
        ]
      }
    ))
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
    ]
  }
}
