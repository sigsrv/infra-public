terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
    }

    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
