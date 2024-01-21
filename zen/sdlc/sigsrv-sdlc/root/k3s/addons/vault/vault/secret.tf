resource "vault_mount" "sigsrv_k3s_secret" {
  path    = "secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "sigsrv_k3s_secret" {
  mount                = vault_mount.sigsrv_k3s_secret.path
  max_versions         = 10
  delete_version_after = 86400
  cas_required         = true
}
