resource "tailscale_tailnet_key" "this" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:sigsrv-incus-network"]
}

resource "incus_instance" "this" {
  name    = var.name
  image   = "images:ubuntu/plucky/cloud"
  type    = "virtual-machine"
  project = "incus-network"
  target  = "sigsrv"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "nvme"
      path = "/"
      size = "10GiB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = var.name
    }
  }

  config = {
    "limits.cpu"           = "1"
    "limits.memory"        = "1GB"
    "cloud-init.user-data" = <<EOF
#cloud-config
packages:
  - curl
write_files:
  - path: /etc/sysctl.d/99-tailscale.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
runcmd:
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  - ['sysctl', '-p', '/etc/sysctl.d/99-tailscale.conf']
  - - 'tailscale'
    - 'up'
    - '--hostname'
    - '${var.name}'
    - '--auth-key=${tailscale_tailnet_key.this.key}'
    - '--advertise-routes=${var.network.ipv4_cidr}'
    - '--accept-routes'
EOF
  }

  depends_on = [tailscale_tailnet_key.this]
}

data "tailscale_device" "this" {
  hostname = var.name
  wait_for = "60s"

  depends_on = [incus_instance.this]
}

resource "tailscale_device_subnet_routes" "this" {
  device_id = data.tailscale_device.this.id
  routes    = [var.network.ipv4_cidr]

  depends_on = [data.tailscale_device.this]
}

resource "tailscale_dns_split_nameservers" "this" {
  domain      = var.network.zone
  nameservers = [cidrhost(var.network.ipv4_cidr, 1)]

  depends_on = [data.tailscale_device.this]
}
