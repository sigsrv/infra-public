locals {
  ipv4_address = replace(var.network.ipv4_cidr, "0/", "1/")
}

resource "incus_network" "this" {
  name        = var.name
  description = "Network this (managed by OpenTofu)"

  config = {
    "dns.domain"       = incus_network_zone.this.name
    "dns.mode"         = "managed"
    "dns.search"       = join(",", ["1.1.1.1", "1.0.0.1"])
    "dns.zone.forward" = incus_network_zone.this.name
    "ipv4.address"     = local.ipv4_address
    "ipv4.nat"         = true
    "ipv6.address"     = "none"
  }

  depends_on = [incus_network.node]
}

resource "incus_network" "node" {
  for_each = toset(["sigsrv", "minisrv"])

  name        = var.name
  description = "Network this (managed by OpenTofu)"
  target      = each.key

  config = {
    "bridge.external_interfaces" = var.network.parent
  }

  lifecycle {
    ignore_changes = [
      config
    ]
  }
}

resource "incus_network_zone" "this" {
  name        = var.network.zone
  description = "Zone incus_network_zone (managed by OpenTofu)"

  config = {
    "peers.ns.address" = "127.0.0.1"
  }
}
