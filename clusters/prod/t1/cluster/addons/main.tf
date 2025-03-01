module "local_path_provisioner" {
  source = "./local-path-provisioner"
}

module "registry" {
  source = "./registry"

  depends_on = [
    module.local_path_provisioner
  ]
}

module "tailscale_operator" {
  source = "./tailscale-operator"
}
