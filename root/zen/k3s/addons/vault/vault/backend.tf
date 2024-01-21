provider "vault" {
  address = "https://vault.deer-neon.ts.net"
}

terraform {
  backend "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-k3s"
    namespace      = "vault"
    secret_suffix  = "vault"
  }
}
