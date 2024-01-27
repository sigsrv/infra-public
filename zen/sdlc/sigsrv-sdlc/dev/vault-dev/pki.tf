resource "vault_mount" "pki" {
  type                      = data.terraform_remote_state.vault.outputs["pki_vault_mount_type"]
  path                      = "dev/pki"
  description               = "pki"
  default_lease_ttl_seconds = 864000
  max_lease_ttl_seconds     = 864000
}

resource "vault_pki_secret_backend_intermediate_cert_request" "pki" {
  backend     = vault_mount.pki.path
  common_name = "sigsrv-sdlc Intermediate CA"
  type        = data.terraform_remote_state.vault.outputs["pki_root_ca_cert_type"]
  key_type    = "ed25519"
  key_bits    = 256
}

resource "vault_pki_secret_backend_root_sign_intermediate" "pki" {
  backend              = data.terraform_remote_state.vault.outputs["pki_vault_mount_path"]
  csr                  = vault_pki_secret_backend_intermediate_cert_request.pki.csr
  common_name          = "sigsrv-sdlc Dev CA"
  exclude_cn_from_sans = true
  ou                   = "sigsrv-sdlc"
  organization         = "sigsrv"
  country              = "KR"
  province             = "Seoul"
  locality             = "Seoul"
  revoke               = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "pki" {
  backend     = vault_mount.pki.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki.certificate
}

resource "vault_pki_secret_backend_config_urls" "pki" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["${data.terraform_remote_state.vault.outputs["internal_url"]}/v1/roach/pki/ca"]
  crl_distribution_points = ["${data.terraform_remote_state.vault.outputs["internal_url"]}/v1/roach/pki/crl"]
}
