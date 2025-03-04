resource "incus_project" "this" {
  name        = var.incus.project_name
  description = "${var.incus.project_name} (managed by OpenTofu)"

  config = merge(
    {
      "features.images"          = true
      "features.profiles"        = true
      "features.storage.buckets" = true
      "features.storage.volumes" = true
      "features.networks"        = false
      "features.networks.zones"  = true
      "limits.containers"        = 16
      "limits.cpu"               = 64
      "limits.disk"              = "20TiB"
      "limits.instances"         = 32
      "limits.memory"            = "64GiB"
      "limits.networks"          = 4
      "limits.virtual-machines"  = 16
    },
    var.incus.project_config,
  )
}

resource "incus_profile" "this" {
  project     = incus_project.this.name
  name        = "default"
  description = "Default Incus profile for project ${incus_project.this.name} (managed by OpenTofu)"

  config = {
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
    "limits.cpu"         = 2
    "limits.memory"      = "4GiB"
    "migration.stateful" = false
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      "nictype" = "bridged"
      "parent"  = var.incus.network_name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      "pool"          = "nvme"
      "path"          = "/"
      "size"          = "100GiB"
      "size.state"    = "16GiB"
      "boot.priority" = 20
    }
  }
}
