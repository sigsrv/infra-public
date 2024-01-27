output "internal_url" {
  value = "http://vault-internal.vault.svc.cluster.local:8200"
}

output "pki_vault_mount_type" {
  value = module.vault-pki.vault_mount_type
}

output "pki_vault_mount_path" {
  value = module.vault-pki.vault_mount_path
}

output "pki_root_ca_cert_type" {
  value = module.vault-pki-root-ca.cert_type
}
