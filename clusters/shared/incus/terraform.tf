terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.2.0"
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
