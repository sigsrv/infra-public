# config
locals {
  kubernetes_cluster_name = "sigsrv-sdlc"

  vault_public_url   = "https://vault-sdlc.deer-neon.ts.net"
  vault_internal_url = "http://vault-internal.vault.svc.cluster.local:8200"
}

# vault auth
module "vault-auth-kubernetes" {
  source = "./auth/kubernetes"
}

module "vault-auth-userpass" {
  source = "./auth/userpass"
}

module "vault-auth-userpass-users-admin" {
  source     = "./auth/userpass/users/admin"
  depends_on = [module.vault-auth-userpass]
}

# vault kubernetes
module "vault-kubernetes" {
  source = "./kubernetes"
}

# vault pki
module "vault-pki" {
  source = "./pki"

  vault_public_url   = local.vault_public_url
  vault_internal_url = local.vault_internal_url

  kubernetes_cluster_name = local.kubernetes_cluster_name
}

# vault secret
module "vault-secret" {
  source = "./secret"
}
