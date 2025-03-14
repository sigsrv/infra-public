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

    phaser = {
      source = "sigsrv/phaser"
    }
  }
}
