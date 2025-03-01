terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.2.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7.0"
    }
  }
}

provider "incus" {
  remote {
    name    = "sigsrv"
    scheme  = "https"
    address = "sigsrv.deer-neon.ts.net"
    default = true
  }
}

provider "talos" {}
