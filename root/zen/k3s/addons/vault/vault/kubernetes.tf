resource "vault_policy" "sigsrv-k3s-1password-vault-auth" {
  name   = "sigsrv-k3s/1password/vault-auth"
  policy = <<EOF
path "sigsrv-k3s/secret/data/addons/1password/*" {
  capabilities = ["read"]
}
EOF
}

resource "vault_kubernetes_auth_backend_role" "sigsrv-k3s-1password-vault-auth" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "1password-sigsrv-k3s-vault-auth"
  bound_service_account_namespaces = ["1password-sigsrv-k3s"]
  bound_service_account_names      = ["vault-auth"]
  token_policies                   = [vault_policy.sigsrv-k3s-1password-vault-auth.name]
}

# 1password-sigsrv-k3s/onepassword-connect
