resource "vault_pki_secret_backend_role" "nodes" {
  backend                     = vault_mount.pki.path
  name                        = "cockroachdb_nodes"
  key_type                    = "ed25519"
  ttl                         = "172800"   # 48h
  max_ttl                     = "31536000" # 8760h
  server_flag                 = true
  client_flag                 = true
  allow_bare_domains          = true
  allow_wildcard_certificates = true
  allowed_domains = [
    "cockroachdb-public",
    "cockroachdb-public.dev.svc.cluster.local",
    "*.cockroachdb",
    "*.cockroachdb.dev.svc.cluster.local",
  ]
}

resource "vault_pki_secret_backend_cert" "nodes" {
  backend              = vault_mount.pki.path
  name                 = vault_pki_secret_backend_role.nodes.name
  common_name          = vault_pki_secret_backend_role.nodes.allowed_domains[0]
  alt_names            = vault_pki_secret_backend_role.nodes.allowed_domains
  exclude_cn_from_sans = true
  ttl                  = "86400" # 24h
}
