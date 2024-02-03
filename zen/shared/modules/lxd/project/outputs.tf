output "lxd_project_name" {
  value = lxd_project.this.name
}

output "lxd_storage_pool_name" {
  value = var.lxd_storage_pool_name
}

output "lxd_profile_name" {
  value = lxd_profile.this.name
}

output "lxd_ubuntu_image_fingerprint" {
  value = lxd_cached_image.ubuntu_vm.fingerprint
}
