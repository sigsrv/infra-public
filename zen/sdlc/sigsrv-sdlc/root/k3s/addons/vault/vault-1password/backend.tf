provider "vault" {
  address = "https://vault-sdlc.deer-neon.ts.net"
}

terraform {
  backend "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-sdlc"
    namespace      = "vault"
    secret_suffix  = "vault-1password"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "sigsrv-sdlc"
}
