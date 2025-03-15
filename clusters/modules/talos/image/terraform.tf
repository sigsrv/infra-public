terraform {
  required_providers {
    talos = {
      source = "siderolabs/talos"
    }
  }
}

locals {
  incus_remote_host = "sigsrv.deer-neon.ts.net"
  incus_remote_user = "ecmaxp"
}
