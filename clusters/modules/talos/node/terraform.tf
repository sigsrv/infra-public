terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
    }

    talos = {
      source = "siderolabs/talos"
    }

    phaser = {
      source = "sigsrv/phaser"
    }
  }
}
