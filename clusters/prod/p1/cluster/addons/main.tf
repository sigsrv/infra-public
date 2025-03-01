module "local_path_provisioner" {
  source = "./local-path-provisioner"

  cluster_name  = var.cluster_name
  cluster_alias = var.cluster_alias
  cluster_env   = var.cluster_env
}

module "registry" {
  source = "./registry"

  cluster_name  = var.cluster_name
  cluster_alias = var.cluster_alias
  cluster_env   = var.cluster_env

  depends_on = [
    module.local_path_provisioner
  ]
}

module "tailscale_operator" {
  source = "./tailscale-operator"

  cluster_name  = var.cluster_name
  cluster_alias = var.cluster_alias
  cluster_env   = var.cluster_env
}
