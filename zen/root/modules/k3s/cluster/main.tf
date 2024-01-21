terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "1.10.2"
    }
  }
}

resource "lxd_instance" "master" {
  count   = var.k3s_cluster_master_instance_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-master-${count.index}"
  image   = var.lxd_ubuntu_image_fingerprint
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.master-k3s-storage[count.index].name,
  ]

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

  config = {}

  lifecycle {
    prevent_destroy = false

    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_instance" "worker" {
  count   = var.k3s_cluster_worker_instance_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-worker-${count.index}"
  image   = var.lxd_ubuntu_image_fingerprint
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.worker-k3s-storage[count.index].name,
  ]

  limits = {
    cpu    = 4
    memory = "8GiB"
  }

  config = {}

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_profile" "master-k3s-storage" {
  count       = var.k3s_cluster_master_instance_count
  project     = var.lxd_project_name
  name        = "${var.k3s_cluster_name}-master-k3s-storage-${count.index}"
  description = var.k3s_cluster_name

  device {
    name = "master-k3s-storage"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      path   = "/var/lib/rancher/k3s/storage"
      source = lxd_volume.master-k3s-storage[count.index].name
    }
  }
}

resource "lxd_profile" "worker-k3s-storage" {
  count       = var.k3s_cluster_worker_instance_count
  project     = var.lxd_project_name
  name        = "${var.k3s_cluster_name}-worker-k3s-storage-${count.index}"
  description = var.k3s_cluster_name

  device {
    name = "worker-k3s-storage"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      path   = "/var/lib/rancher/k3s/storage"
      source = lxd_volume.worker-k3s-storage[count.index].name
    }
  }
}

resource "lxd_volume" "master-k3s-storage" {
  count   = var.k3s_cluster_master_instance_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-master-k3s-storage-${count.index}"
  pool    = var.lxd_storage_pool_name
  config = {
    size                 = "1TiB"
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "lxd_volume" "worker-k3s-storage" {
  count   = var.k3s_cluster_worker_instance_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-worker-k3s-storage-${count.index}"
  pool    = var.lxd_storage_pool_name
  config = {
    size                 = "1TiB"
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}
