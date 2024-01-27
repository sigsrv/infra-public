provider "vault" {
  address = var.vault_address
}

terraform {
  backend "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-sdlc"
    namespace      = "vault"
    secret_suffix  = "vault"
  }
}
