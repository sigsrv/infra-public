// sigsrv-k3s
resource "vault_mount" "sigsrv_k3s_secret" {
  path    = "sigsrv-k3s/secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "sigsrv_k3s_secret" {
  mount                = vault_mount.sigsrv_k3s_secret.path
  max_versions         = 10
  delete_version_after = 86400
  cas_required         = true
}

// sigsrv-sdlc
resource "vault_mount" "sigsrv_sdlc_secret" {
  path    = "sigsrv-sdlc/secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "sigsrv_sdlc_secret" {
  mount                = vault_mount.sigsrv_sdlc_secret.path
  max_versions         = 10
  delete_version_after = 86400
  cas_required         = true
}

// sigsrv-prod
resource "vault_mount" "sigsrv_prod_secret" {
  path    = "sigsrv-prod/secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "sigsrv_prod_secret" {
  mount                = vault_mount.sigsrv_prod_secret.path
  max_versions         = 10
  delete_version_after = 86400
  cas_required         = true
}
