resource "vault_mount" "pki" {
  type                      = "pki"
  path                      = "pki"
  default_lease_ttl_seconds = 157680000 # 5y
  max_lease_ttl_seconds     = 315360000 # 10y
}

resource "vault_pki_secret_backend_config_urls" "pki" {
  backend = vault_mount.pki.path
  issuing_certificates = [
    "${var.vault_public_url}/v1/${vault_mount.pki.path}/ca",
    "${var.vault_internal_url}/v1/${vault_mount.pki.path}/ca",
  ]
  crl_distribution_points = [
    "${var.vault_public_url}/v1/${vault_mount.pki.path}/crl",
    "${var.vault_internal_url}/v1/${vault_mount.pki.path}/crl",
  ]
}

resource "vault_pki_secret_backend_root_cert" "root_ca" {
  backend              = vault_mount.pki.path
  type                 = "internal"
  common_name          = "${var.kubernetes_cluster_name} Root CA"
  ttl                  = "87600h" # 10 years
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "sigsrv-prod"
  organization         = "sigsrv"
  country              = "KR"
  province             = "Seoul"
  locality             = "Seoul"

  lifecycle {
    prevent_destroy = true
  }
}
