# https://deployment.properties/posts/devsecops/cockroachdb-vault-pki-certmanager/#checkpoint
# https://developer.hashicorp.com/vault/docs/secrets/pki/quick-start-root-ca
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_set_signed
resource "vault_pki_secret_backend_role" "clients" {
  backend                     = vault_mount.pki.path
  name                        = "cockroachdb_client"
  key_type                    = "ed25519"
  ttl                         = "172800"   # 48h
  max_ttl                     = "31536000" # 8760h
  server_flag                 = true
  client_flag                 = false
  allow_bare_domains          = true
  allow_wildcard_certificates = true
  allowed_domains = [
    "cockroachdb-public",
    "cockroachdb-public.dev.svc.cluster.local",
  ]
}

resource "vault_pki_secret_backend_cert" "clients" {
  backend              = vault_mount.pki.path
  name                 = vault_pki_secret_backend_role.clients.name
  common_name          = vault_pki_secret_backend_role.clients.allowed_domains[0]
  alt_names            = vault_pki_secret_backend_role.clients.allowed_domains
  exclude_cn_from_sans = true
  ttl                  = "86400" # 24h
}
