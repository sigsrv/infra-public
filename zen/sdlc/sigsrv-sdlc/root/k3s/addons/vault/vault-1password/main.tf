locals {
  name      = "onepassword-connector"
  namespace = "1password"
  policy    = <<EOF
path "secret/data/addon/1password/*" {
  capabilities = ["read"]
}
EOF
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
