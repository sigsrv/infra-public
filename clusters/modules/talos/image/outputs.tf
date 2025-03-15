output "incus_iso_volume" {
  value = local.incus_talos_iso_volume
}

output "urls" {
  value = {
    installer_secureboot = data.talos_image_factory_urls.this.urls.installer_secureboot
    iso_secureboot       = data.talos_image_factory_urls.this.urls.iso_secureboot
  }
}
