output "vault_public_url" {
  value = local.vault_public_url
}

output "vault_internal_url" {
  value = local.vault_internal_url
}

output "vault_root_pki_path" {
  value = module.vault-pki.vault_mount_path
}

output "vault_root_pki_ca_cert_type" {
  value = module.vault-pki.vault_root_ca_cert_type
}

output "vault_root_pki_ca_cert_certificate" {
  value = module.vault-pki.vault_root_ca_cert_certificate
}
