locals {
  vault_path = (
    var.kubernetes_app_role != null ?
    "app/${var.kubernetes_app_namespace}/${var.kubernetes_app_name}/${var.kubernetes_app_role}" :
    "app/${var.kubernetes_app_namespace}/${var.kubernetes_app_name}"
  )

  ca_name = (
    var.kubernetes_app_role != null ?
    "${var.kubernetes_cluster_name} ${var.kubernetes_app_namespace} ${var.kubernetes_app_name} ${var.kubernetes_app_role}" :
    "${var.kubernetes_cluster_name} ${var.kubernetes_app_namespace} ${var.kubernetes_app_name}"
  )
}

resource "vault_mount" "app-pki" {
  type                      = "pki"
  path                      = "${local.vault_path}/pki"
  default_lease_ttl_seconds = 31536000  # 1y
  max_lease_ttl_seconds     = 157680000 # 5y
}

resource "vault_pki_secret_backend_config_urls" "app-pki" {
  backend = vault_mount.app-pki.path
  issuing_certificates = [
    "${var.vault_public_url}/v1/${vault_mount.app-pki.path}/ca",
    "${var.vault_internal_url}/v1/${vault_mount.app-pki.path}/ca",
  ]
  crl_distribution_points = [
    "${var.vault_public_url}/v1/${vault_mount.app-pki.path}/crl",
    "${var.vault_internal_url}/v1/${vault_mount.app-pki.path}/crl",
  ]
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  backend      = vault_mount.app-pki.path
  common_name  = "${local.ca_name} Intermediate CA"
  type         = var.vault_pki_ca_cert_type
  key_type     = "rsa"
  key_bits     = 4096
  ou           = var.kubernetes_cluster_name
  organization = "sigsrv"
  country      = "KR"
  province     = "Seoul"
  locality     = "Seoul"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend              = var.vault_pki_path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = vault_pki_secret_backend_intermediate_cert_request.intermediate.common_name
  exclude_cn_from_sans = true
  revoke               = true
  ttl                  = 157680000 # 5y
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend = vault_mount.app-pki.path
  certificate = join("\n", [
    vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate,
    var.vault_pki_ca_cert_certificate,
  ])
}
