resource "vault_pki_secret_backend_root_cert" "root_ca" {
  backend              = var.pki_mount_path
  type                 = "internal"
  common_name          = "sigsrv-sdlc Root CA"
  ttl                  = "8760h"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "ed25519"
  key_bits             = 256
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
