data "vault_auth_backend" "kubernetes" {
  path = "kubernetes"
}

data "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend = data.vault_auth_backend.kubernetes.path
}

resource "vault_kubernetes_secret_backend" "kubernetes" {
  path            = "kubernetes"
  kubernetes_host = data.vault_kubernetes_auth_backend_config.kubernetes.kubernetes_host
}
