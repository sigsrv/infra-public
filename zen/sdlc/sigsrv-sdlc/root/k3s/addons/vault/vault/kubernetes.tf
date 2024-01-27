resource "vault_policy" "onepassword-vault-auth" {
  name   = "onepassword/vault-auth"
  policy = <<EOF
path "sigsrv-k3s/secret/data/addons/onepassword/*" {
  capabilities = ["read"]
}
EOF
}

resource "vault_kubernetes_auth_backend_role" "onepassword-vault-auth" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "onepassword-vault-auth"
  bound_service_account_namespaces = ["onepassword"]
  bound_service_account_names      = ["vault-auth"]
  token_policies                   = [vault_policy.onepassword-vault-auth.name]
}

# onepassword-onepassword-connect
