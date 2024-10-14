resource "vault_mount" "pki" {
  type                      = "pki"
  path                      = "pki"
  default_lease_ttl_seconds = 315360000  # 10y
  max_lease_ttl_seconds     = 3153600000 # 100y
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
  ttl                  = "876000h" # 100 years
  format               = "pem"
  private_key_format   = "der"
  key_type             = "ec"
  key_bits             = 384
  exclude_cn_from_sans = true
  ou                   = "sigsrv-sdlc"
  organization         = "sigsrv"
  country              = "KR"
  province             = "Seoul"
  locality             = "Seoul"

  lifecycle {
    prevent_destroy = true
  }
}
