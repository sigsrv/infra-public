locals {
  count = var.status == "running" ? 1 : 0
}

module "argocd" {
  source = "./argocd"
  count  = var.addons.argocd.enabled ? local.count : 0

  kubernetes  = var.kubernetes
  tailscale   = var.tailscale
  onepassword = var.onepassword
  argocd      = var.addons.argocd

  depends_on = [
    module.tailscale_operator,
  ]
}

module "cert_manager" {
  source = "./cert-manager"
  count  = var.addons.cert_manager.enabled ? local.count : 0

  kubernetes   = var.kubernetes
  cert_manager = var.addons.cert_manager
}

module "cloudnative_pg" {
  source = "./cloudnative-pg"
  count  = var.addons.cloudnative_pg.enabled ? local.count : 0

  kubernetes     = var.kubernetes
  cloudnative_pg = var.addons.cloudnative_pg

  depends_on = [
    module.seaweedfs,
  ]
}

module "metrics_server" {
  source = "./metrics-server"
  count  = var.addons.metrics_server.enabled ? local.count : 0

  kubernetes     = var.kubernetes
  metrics_server = var.addons.metrics_server
}

module "local_path_provisioner" {
  source = "./local-path-provisioner"
  count  = var.addons.local_path_provisioner.enabled ? local.count : 0

  kubernetes             = var.kubernetes
  local_path_provisioner = var.addons.local_path_provisioner
}

module "registry" {
  source = "./registry"
  count  = var.addons.registry.enabled ? local.count : 0

  kubernetes = var.kubernetes
  registry   = var.addons.registry

  depends_on = [
    module.seaweedfs,
    module.tailscale_operator,
  ]
}

module "seaweedfs" {
  source = "./seaweedfs"
  count  = var.addons.seaweedfs.enabled ? local.count : 0

  kubernetes = var.kubernetes
  seaweedfs  = var.addons.seaweedfs

  depends_on = [
    module.cert_manager,
    module.local_path_provisioner,
  ]
}

module "tailscale_operator" {
  source = "./tailscale-operator"
  count  = var.addons.tailscale_operator.enabled ? local.count : 0

  kubernetes         = var.kubernetes
  onepassword        = var.onepassword
  tailscale_operator = var.addons.tailscale_operator
}

module "openbao" {
  source = "./openbao"
  count  = var.addons.openbao.enabled ? local.count : 0

  kubernetes  = var.kubernetes
  onepassword = var.onepassword
  openbao     = var.addons.openbao

  depends_on = [
    module.seaweedfs,
    module.tailscale_operator,
  ]
}
