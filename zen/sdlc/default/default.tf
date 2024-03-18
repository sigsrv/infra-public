terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
  }
}

# TODO: lxd remote

resource "lxd_instance" "nixos-test" {
  project = "default"
  name    = "nixos-test"
  image   = "nixos-unstable-vm"
  type    = "virtual-machine"

  profiles = ["default"]

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

module "nixos-test-conf" {
  source   = "../../shared/modules/lxd/nixos"
  project  = lxd_instance.nixos-test.project
  instance = lxd_instance.nixos-test.name
  config   = {
    default = file("nixos-test.nix")
  }
}
