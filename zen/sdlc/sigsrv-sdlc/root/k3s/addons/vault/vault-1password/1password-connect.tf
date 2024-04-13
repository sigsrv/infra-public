locals {
  name      = "onepassword-connector"
  namespace = "1password"
  policy    = <<EOF
path "secret/data/addon/1password/*" {
  capabilities = ["read"]
}
EOF
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

provider "vault" {
  address = "https://vault-sdlc.deer-neon.ts.net"
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = local.name
    namespace = local.namespace
  }
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = "kubernetes"
  role_name                        = "${local.namespace}-${local.name}"
  bound_service_account_names      = [local.name]
  bound_service_account_namespaces = [local.namespace]
  token_policies                   = [vault_policy.this.name]
}

resource "vault_policy" "this" {
  name   = "app/${local.namespace}/${local.name}"
  policy = local.policy
}
