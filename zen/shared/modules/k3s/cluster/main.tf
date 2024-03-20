terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
  }
}

resource "lxd_instance" "k3s-master" {
  count   = var.k3s_master_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-k3s-master-${count.index}"
  image   = var.lxd_nixos_image_alias
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.k3s-master-data[count.index].name,
  ]

  limits = {
    cpu    = 2
    memory = "4GiB"
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

resource "lxd_instance" "k3s-worker" {
  count   = var.k3s_worker_count
  project = var.lxd_project_name
  name    = "${var.k3s_cluster_name}-k3s-worker-${count.index}"
  image   = var.lxd_nixos_image_alias
  type    = "virtual-machine"

  profiles = [
    var.lxd_profile_name,
    lxd_profile.k3s-worker-data[count.index].name,
  ]

  limits = {
    cpu    = 4
    memory = "8GiB"
  }

  lifecycle {
    ignore_changes = [
      image,
      config["cloud-init.user-data"],
      device,
    ]
  }
}

resource "lxd_profile" "k3s-master-data" {
  count       = var.k3s_master_count
  project     = var.lxd_project_name
  name        = "${var.k3s_cluster_name}-k3s-master-data-${count.index}"
  description = var.k3s_cluster_name

  device {
    name = "k3s-master-data"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      source = lxd_volume.k3s-master-data[count.index].name
    }
  }
}

resource "lxd_profile" "k3s-worker-data" {
  count       = var.k3s_worker_count
  project     = var.lxd_project_name
  name        = "${var.k3s_cluster_name}-k3s-worker-data-${count.index}"
  description = var.k3s_cluster_name

  device {
    name = "k3s-worker-data"
    type = "disk"
    properties = {
      pool   = var.lxd_storage_pool_name
      source = lxd_volume.k3s-worker-data[count.index].name
    }
  }
}

resource "lxd_volume" "k3s-master-data" {
  count        = var.k3s_master_count
  project      = var.lxd_project_name
  name         = "${var.k3s_cluster_name}-k3s-master-data-${count.index}"
  pool         = var.lxd_storage_pool_name
  content_type = "block"

  config = {
    size                 = "1TiB"
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "lxd_volume" "k3s-worker-data" {
  count        = var.k3s_worker_count
  project      = var.lxd_project_name
  name         = "${var.k3s_cluster_name}-k3s-worker-data-${count.index}"
  pool         = var.lxd_storage_pool_name
  content_type = "block"

  config = {
    size                 = "1TiB"
    "snapshots.expiry"   = "4w"
    "snapshots.schedule" = "@daily"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "null_resource" "k3s-master-data-format" {
  count = var.k3s_master_count

  triggers = {
    lxd_remote_name   = var.lxd_remote_name
    lxd_project_name  = var.lxd_project_name
    lxd_instance_name = lxd_instance.k3s-master[count.index].name
    lxd_volume_name   = lxd_volume.k3s-master-data[count.index].name
  }

  provisioner "local-exec" {
    command = join(" ", [
      "lxc",
      "exec",
      "${var.lxd_remote_name}:${lxd_instance.k3s-master[count.index].name}",
      "--project",
      var.lxd_project_name,
      "--",
      "/run/current-system/sw/bin/mkfs.ext4",
      "-L",
      "data",
      "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:1",
    ])
  }
}

resource "null_resource" "k3s-worker-data-format" {
  count = var.k3s_worker_count

  triggers = {
    lxd_remote_name   = var.lxd_remote_name
    lxd_project_name  = var.lxd_project_name
    lxd_instance_name = lxd_instance.k3s-worker[count.index].name
    lxd_volume_name   = lxd_volume.k3s-worker-data[count.index].name
  }

  provisioner "local-exec" {
    command = join(" ", [
      "lxc",
      "exec",
      "${var.lxd_remote_name}:${lxd_instance.k3s-worker[count.index].name}",
      "--project",
      var.lxd_project_name,
      "--",
      "/run/current-system/sw/bin/mkfs.ext4",
      "-L",
      "data",
      "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:1",
    ])
  }
}

module "k3s-master-nixos-0" {
  source = "../../lxd/nixos"

  depends_on = [
    null_resource.k3s-master-data-format,
  ]

  lxd_remote_name   = var.lxd_remote_name
  lxd_project_name  = var.lxd_project_name
  lxd_instance_name = lxd_instance.k3s-master[0].name
  lxd_dns_servers   = var.lxd_dns_servers
  lxd_dns_domain    = var.lxd_dns_domain

  nixos_config = {
    k3s-service = templatefile("${path.module}/k3s-service.nix", {
      k3s_role        = "server"
      k3s_token_file  = lxd_instance_file.k3s-cluster-token.target_path
      k3s_config_path = lxd_instance_file.k3s-master-config-0.target_path
    })
    k3s-data = file("${path.module}/k3s-data.nix")
  }
}

module "k3s-master-nixos-1" {
  count  = var.k3s_master_count - 1
  source = "../../lxd/nixos"

  depends_on = [
    null_resource.k3s-master-data-format,
  ]

  lxd_remote_name   = var.lxd_remote_name
  lxd_project_name  = var.lxd_project_name
  lxd_instance_name = lxd_instance.k3s-master[count.index + 1].name
  lxd_dns_servers   = var.lxd_dns_servers
  lxd_dns_domain    = var.lxd_dns_domain

  nixos_config = {
    k3s-service = templatefile("${path.module}/k3s-service.nix", {
      k3s_role        = "server"
      k3s_token_file  = lxd_instance_file.k3s-master-token-1[count.index].target_path
      k3s_config_path = lxd_instance_file.k3s-master-config-1[count.index].target_path
    })
    k3s-data = file("${path.module}/k3s-data.nix")
  }
}

module "k3s-worker-nixos" {
  count  = var.k3s_worker_count
  source = "../../lxd/nixos"

  depends_on = [
    null_resource.k3s-worker-data-format,
  ]

  lxd_remote_name   = var.lxd_remote_name
  lxd_project_name  = var.lxd_project_name
  lxd_instance_name = lxd_instance.k3s-worker[count.index].name
  lxd_dns_servers   = var.lxd_dns_servers
  lxd_dns_domain    = var.lxd_dns_domain

  nixos_config = {
    k3s-service = templatefile("${path.module}/k3s-service.nix", {
      k3s_role        = "agent"
      k3s_token_file  = lxd_instance_file.k3s-worker-token[count.index].target_path
      k3s_config_path = lxd_instance_file.k3s-worker-config[count.index].target_path
    })
    k3s-data = file("${path.module}/k3s-data.nix")
  }
}

locals {
  master_k3s_server_url = "https://${lxd_instance.k3s-master[0].name}.${var.lxd_dns_domain}:6443"
}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-master-config-0" {
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-master[0].name
  target_path = "/etc/nixos/k3s-config"
  mode        = "0600"
  content = jsonencode({
    cluster-init       = true
    server             = null
    secrets-encryption = true
    flannel-backend    = "wireguard-native"
    node-taint         = ["node-role.kubernetes.io/master=true:NoSchedule"]
    tls-san = [
      lxd_instance.k3s-master[0].name,
      "${lxd_instance.k3s-master[0].name}.${var.lxd_dns_domain}",
    ]
  })
}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-master-config-1" {
  count       = var.k3s_master_count - 1
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-master[count.index + 1].name
  target_path = "/etc/nixos/k3s-config"
  mode        = "0600"
  content = jsonencode({
    cluster-init       = false
    server             = local.master_k3s_server_url
    secrets-encryption = true
    flannel-backend    = "wireguard-native"
    node-taint         = ["node-role.kubernetes.io/master=true:NoSchedule"]
    tls-san = [
      lxd_instance.k3s-master[count.index + 1].name,
      "${lxd_instance.k3s-master[count.index + 1].name}.${var.lxd_dns_domain}",
    ]
  })
}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-worker-config" {
  count       = var.k3s_worker_count
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-worker[count.index].name
  target_path = "/etc/nixos/k3s-config"
  mode        = "0600"
  content = jsonencode({
    server = local.master_k3s_server_url
  })
}

resource "random_uuid" "k3s-cluster-token" {}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-cluster-token" {
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-master[0].name
  target_path = "/etc/nixos/k3s-cluster-token"
  mode        = "0600"
  content     = random_uuid.k3s-cluster-token.result
}

data "external" "k3s-master-token-0" {
  depends_on = [
    module.k3s-master-nixos-0,
  ]

  program = [
    "python3",
    "-c",
    "import sys, subprocess, json; print(json.dumps({\"output\": subprocess.check_output(sys.argv[1:], text=True)}))",
    "lxc",
    "exec",
    "${var.lxd_remote_name}:${lxd_instance.k3s-master[0].name}",
    "--project",
    var.lxd_project_name,
    "--",
    "cat",
    "/var/lib/rancher/k3s/server/node-token",
  ]
}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-master-token-1" {
  count       = var.k3s_master_count - 1
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-master[count.index + 1].name
  target_path = "/etc/nixos/k3s-node-token"
  mode        = "0600"
  content     = sensitive(data.external.k3s-master-token-0.result["output"])
}

//noinspection MissingProperty
resource "lxd_instance_file" "k3s-worker-token" {
  count       = var.k3s_worker_count
  project     = var.lxd_project_name
  instance    = lxd_instance.k3s-worker[count.index].name
  target_path = "/etc/nixos/k3s-node-token"
  mode        = "0600"
  content     = sensitive(data.external.k3s-master-token-0.result["output"])
}
