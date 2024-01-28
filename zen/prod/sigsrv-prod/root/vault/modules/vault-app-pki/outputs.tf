output "vault_pki_path" {
  value = vault_mount.app-pki.path
}

output "vault_pki_ca_cert_type" {
  value = vault_pki_secret_backend_intermediate_cert_request.intermediate.type
}

output "vault_pki_ca_cert_certificate" {
  value = vault_pki_secret_backend_intermediate_set_signed.intermediate.certificate
}
