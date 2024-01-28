output "vault_mount_path" {
  value = vault_mount.pki.path
}

output "vault_root_ca_cert_type" {
  value = vault_pki_secret_backend_root_cert.root_ca.type
}

output "vault_root_ca_cert_certificate" {
  value = vault_pki_secret_backend_root_cert.root_ca.certificate
}
