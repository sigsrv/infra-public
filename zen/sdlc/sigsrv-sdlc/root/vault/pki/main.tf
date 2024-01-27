resource "vault_mount" "pki" {
  type                      = "pki"
  path                      = "pki"
  default_lease_ttl_seconds = 8640000
  max_lease_ttl_seconds     = 8640000
}
