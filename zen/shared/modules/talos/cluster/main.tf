terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }
  }
}

resource "lxd_instance" "talos-master" {
  count   = var.talos_master_count
  project = var.lxd_project_name
  name    = "${var.talos_cluster_name}-talos-master-${count.index}"
  image   = var.lxd_nixos_image_alias
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.talos-master-data[count.index].name,
  ]

  limits = {
    cpu    = 1
    memory = "1GiB"
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_instance" "talos-worker" {
  count   = var.talos_worker_count
  project = var.lxd_project_name
  name    = "${var.talos_cluster_name}-talos-worker-${count.index}"
  image   = var.lxd_nixos_image_alias
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.talos-worker-data[count.index].name,
  ]

  limits = {
    cpu    = 2
    memory = "2GiB"
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_profile" "talos-master-data" {
  count       = var.talos_master_count
  project     = var.lxd_project_name
  name        = "${var.talos_cluster_name}-talos-master-data-${count.index}"
  description = var.talos_cluster_name

  device {
    name = "talos-master-data"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      source = lxd_volume.talos-master-data[count.index].name
    }
  }
}

resource "lxd_profile" "talos-worker-data" {
  count       = var.talos_worker_count
  project     = var.lxd_project_name
  name        = "${var.talos_cluster_name}-talos-worker-data-${count.index}"
  description = var.talos_cluster_name

  device {
    name = "talos-worker-data"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      source = lxd_volume.talos-worker-data[count.index].name
    }
  }
}

resource "lxd_volume" "talos-master-data" {
  count        = var.talos_master_count
  project      = var.lxd_project_name
  name         = "${var.talos_cluster_name}-talos-master-data-${count.index}"
  pool         = var.lxd_storage_pool_name
  content_type = "block"

  config = {
    size = "10GB"
    # "snapshots.expiry"   = "4w"
    # "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "lxd_volume" "talos-worker-data" {
  count        = var.talos_worker_count
  project      = var.lxd_project_name
  name         = "${var.talos_cluster_name}-talos-worker-data-${count.index}"
  pool         = var.lxd_storage_pool_name
  content_type = "block"

  config = {
    size = "10GB"
    # "snapshots.expiry"   = "4w"
    # "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}
