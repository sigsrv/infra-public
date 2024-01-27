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
}

module "vault-pki-root-ca" {
  source     = "./pki/root-ca"
  depends_on = [module.vault-pki]

  pki_mount_path = module.vault-pki.vault_mount_path
}

# vault secret
module "vault-secret" {
  source = "./secret"
}
