data "talos_image_factory_urls" "this" {
  talos_version = var.talos.version
  architecture  = "amd64"
  platform      = "metal"
  schematic_id  = talos_image_factory_schematic.this.id
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(var.talos.image_schematic)
}

locals {
  talos_image   = data.talos_image_factory_urls.this
  talos_version = trimprefix(local.talos_image.talos_version, "v")
  talos_iso_url = local.talos_image.urls.iso_secureboot
  talos_iso_filename = "${join("-", [
    "talos",
    local.talos_image.architecture,
    local.talos_image.platform,
    local.talos_image.talos_version,
    substr(local.talos_image.schematic_id, 0, 8),
    "secureboot",
  ])}.iso"
  incus_talos_iso_volume = trimsuffix(local.talos_iso_filename, ".iso")
}

resource "null_resource" "talos_image" {
  triggers = {
    talos_iso_url          = data.talos_image_factory_urls.this.urls.iso_secureboot
    incus_talos_iso_volume = local.incus_talos_iso_volume
    incus_project_name     = var.incus.project_name
  }

  connection {
    type = "ssh"
    host = local.incus_remote_host
    user = local.incus_remote_user
  }

  provisioner "remote-exec" {
    inline = flatten([
      "mkdir -p ~/incus-images/",
      "cd ~/incus-images/",
      "TALOS_VERSION='${local.talos_version}'",
      "TALOS_ISO_URL='${local.talos_iso_url}'",
      "TALOS_ISO_FILENAME='${local.talos_iso_filename}'",
      "INCUS_PROJECT_NAME='${var.incus.project_name}'",
      "INCUS_TALOS_ISO_VOLUME='${local.incus_talos_iso_volume}'",
      "wget -nc \"$TALOS_ISO_URL\" -O $TALOS_ISO_FILENAME",
      [for target in ["sigsrv", "minisrv"] : [
        "incus storage volume delete --project $INCUS_PROJECT_NAME iso $INCUS_TALOS_ISO_VOLUME --target ${target}",
        "incus storage volume import --project $INCUS_PROJECT_NAME --type=iso iso $TALOS_ISO_FILENAME $INCUS_TALOS_ISO_VOLUME --target ${target}",
      ]],
    ])
  }
}
