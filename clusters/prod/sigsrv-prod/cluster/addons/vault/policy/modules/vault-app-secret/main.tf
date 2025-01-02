locals {
  vault_path = (
    var.kubernetes_app_role != null ?
    "app/${var.kubernetes_app_namespace}/${var.kubernetes_app_name}/${var.kubernetes_app_role}" :
    "app/${var.kubernetes_app_namespace}/${var.kubernetes_app_name}"
  )
}

resource "vault_mount" "secret" {
  path    = "${local.vault_path}/secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "secret" {
  mount                = vault_mount.secret.path
  max_versions         = 10
  delete_version_after = 86400
  cas_required         = true
}
