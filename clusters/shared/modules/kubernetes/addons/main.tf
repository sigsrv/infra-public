module "argocd" {
  source = "./argocd"
  count  = var.addons.argocd.enabled ? 1 : 0

  kubernetes  = var.kubernetes
  tailscale   = var.tailscale
  onepassword = var.onepassword
  argocd      = var.addons.argocd
}

module "cert_manager" {
  source = "./cert-manager"
  count  = var.addons.cert_manager.enabled ? 1 : 0

  kubernetes   = var.kubernetes
  cert_manager = var.addons.cert_manager

  depends_on = [
    module.local_path_provisioner,
  ]
}

module "cloudnative_pg" {
  source = "./cloudnative-pg"
  count  = var.addons.cloudnative_pg.enabled ? 1 : 0

  kubernetes     = var.kubernetes
  cloudnative_pg = var.addons.cloudnative_pg

  depends_on = [
    module.local_path_provisioner,
  ]
}

module "metrics_server" {
  source = "./metrics-server"
  count  = var.addons.metrics_server.enabled ? 1 : 0

  kubernetes     = var.kubernetes
  metrics_server = var.addons.metrics_server
}

module "local_path_provisioner" {
  source = "./local-path-provisioner"
  count  = var.addons.local_path_provisioner.enabled ? 1 : 0

  kubernetes             = var.kubernetes
  local_path_provisioner = var.addons.local_path_provisioner
}

module "registry" {
  source = "./registry"
  count  = var.addons.registry.enabled ? 1 : 0

  kubernetes = var.kubernetes
  registry   = var.addons.registry

  depends_on = [
    module.local_path_provisioner,
  ]
}

module "tailscale_operator" {
  source = "./tailscale-operator"
  count  = var.addons.tailscale_operator.enabled ? 1 : 0

  kubernetes         = var.kubernetes
  onepassword        = var.onepassword
  tailscale_operator = var.addons.tailscale_operator
}

module "openbao" {
  source = "./openbao"
  count  = var.addons.openbao.enabled ? 1 : 0

  kubernetes  = var.kubernetes
  onepassword = var.onepassword
  openbao     = var.addons.openbao

  depends_on = [
    module.local_path_provisioner,
  ]
}
