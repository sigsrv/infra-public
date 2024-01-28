locals {
  kubernetes_cluster_name  = "sigsrv-sdlc"
  kubernetes_app_namespace = "dev"
  kubernetes_app_name      = "dev"

  cockroachdb_cluster_name = "cockroachdb"

  vault_public_url                   = data.terraform_remote_state.vault.outputs["vault_public_url"]
  vault_internal_url                 = data.terraform_remote_state.vault.outputs["vault_internal_url"]
  vault_root_pki_path                = data.terraform_remote_state.vault.outputs["vault_root_pki_path"]
  vault_root_pki_ca_cert_type        = data.terraform_remote_state.vault.outputs["vault_root_pki_ca_cert_type"]
  vault_root_pki_ca_cert_certificate = data.terraform_remote_state.vault.outputs["vault_root_pki_ca_cert_certificate"]
}

module "vault_app_secret" {
  source = "../../../root/vault/modules/vault-app-secret"

  kubernetes_cluster_name  = local.kubernetes_cluster_name
  kubernetes_app_namespace = local.kubernetes_app_namespace
  kubernetes_app_name      = local.kubernetes_app_name
}

module "vault_app_pki" {
  source = "../../../root/vault/modules/vault-app-pki"

  kubernetes_cluster_name  = local.kubernetes_cluster_name
  kubernetes_app_namespace = local.kubernetes_app_namespace
  kubernetes_app_name      = local.kubernetes_app_name

  vault_public_url              = local.vault_public_url
  vault_internal_url            = local.vault_internal_url
  vault_pki_path                = local.vault_root_pki_path
  vault_pki_ca_cert_type        = local.vault_root_pki_ca_cert_type
  vault_pki_ca_cert_certificate = local.vault_root_pki_ca_cert_certificate
}

module "vault_app_cockroachdb_pki" {
  source = "../../../root/vault/modules/vault-app-pki"

  kubernetes_cluster_name  = local.kubernetes_cluster_name
  kubernetes_app_namespace = local.kubernetes_app_namespace
  kubernetes_app_name      = local.kubernetes_app_name
  kubernetes_app_role      = "cockroachdb"

  vault_public_url              = local.vault_public_url
  vault_internal_url            = local.vault_internal_url
  vault_pki_path                = module.vault_app_pki.vault_pki_path
  vault_pki_ca_cert_type        = module.vault_app_pki.vault_pki_ca_cert_type
  vault_pki_ca_cert_certificate = module.vault_app_pki.vault_pki_ca_cert_certificate
}
