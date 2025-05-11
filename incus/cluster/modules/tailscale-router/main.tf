resource "tailscale_tailnet_key" "this" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:sigsrv-incus-network"]
}

resource "incus_instance" "this" {
  name    = var.name
  image   = "ghcr:tailscale/tailscale:latest"
  project = "incus-network"
  target  = "sigsrv"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "nvme"
      path = "/"
      size = "20GiB"
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
    "limits.cpu"              = "1"
    "limits.memory"           = "1GB"
    "oci.cwd"                 = "/"
    "oci.entrypoint"          = "/usr/local/bin/containerboot"
    "oci.gid"                 = "0"
    "oci.uid"                 = "0"
    "environment.TS_HOSTNAME" = var.name
    "environment.TS_AUTHKEY"  = tailscale_tailnet_key.this.key
    "environment.TS_ROUTES"   = var.network.ipv4_cidr
  }

  depends_on = [tailscale_tailnet_key.this]
}

data "tailscale_device" "this" {
  hostname = incus_instance.this.config["environment.TS_HOSTNAME"]
  wait_for = "60s"

  depends_on = [incus_instance.this]
}

resource "tailscale_device_subnet_routes" "this" {
  device_id = data.tailscale_device.this.id
  routes    = split(",", incus_instance.this.config["environment.TS_ROUTES"])

  depends_on = [data.tailscale_device.this]
}

resource "tailscale_dns_split_nameservers" "this" {
  domain      = var.network.zone
  nameservers = [cidrhost(var.network.ipv4_cidr, 1)]

  depends_on = [data.tailscale_device.this]
}
