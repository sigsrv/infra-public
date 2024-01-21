locals {
  kubernetes_host = "https://10.64.105.133:6443"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

# vault write auth/userpass/users/admin policies=admin password=(read -s)

resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("admin-policy.hcl")
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = local.kubernetes_host
}

resource "vault_kubernetes_secret_backend" "kubernetes" {
  path            = "kubernetes"
  kubernetes_host = local.kubernetes_host
}
