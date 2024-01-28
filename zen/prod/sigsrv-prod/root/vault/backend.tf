provider "vault" {
  address = "https://vault-prod.deer-neon.ts.net"
}

terraform {
  backend "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-prod"
    namespace      = "vault"
    secret_suffix  = "vault"
  }
}
