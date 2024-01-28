provider "vault" {
  address = "https://vault-sdlc.deer-neon.ts.net"
}

terraform {
  backend "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-sdlc"
    namespace      = "vault"
    secret_suffix  = "vault-dev"
  }
}

data "terraform_remote_state" "vault" {
  backend = "kubernetes"
  config = {
    config_path    = "~/.kube/config"
    config_context = "sigsrv-sdlc"
    namespace      = "vault"
    secret_suffix  = "vault"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "sigsrv-sdlc"
}
