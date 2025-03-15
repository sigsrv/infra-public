locals {
  hostname = "${var.node.name}.${var.incus.network_zone_name}"
}

resource "phaser_sequential" "this" {
  phases = ["ready", "running"]
}

resource "incus_instance" "this" {
  project = var.incus.project_name
  name    = var.node.name
  type    = "virtual-machine"
  target  = var.node.target
  running = phaser_sequential.this.phase == "running"

  config = {
    "limits.cpu"              = var.node.cpu
    "limits.memory"           = var.node.memory
    "user.talos.machine.type" = var.node.type
    "user.incus.hostname"     = local.hostname
    "user.incus.target"       = var.node.target
  }

  device {
    name       = "tpm"
    type       = "tpm"
    properties = {}
  }

  device {
    name = "iso-volume"
    type = "disk"
    properties = {
      "pool"          = "iso"
      "source"        = var.image.incus_iso_volume
      "boot.priority" = 10
    }
  }
}

# incus network zone records
resource "incus_network_zone_record" "this" {
  count = phaser_sequential.this.phase == "running" ? 1 : 0

  zone = var.incus.network_zone_name
  name = incus_instance.this.name

  entry {
    type  = "A"
    value = incus_instance.this.ipv4_address
    ttl   = 60
  }

  depends_on = [
    incus_instance.this,
  ]
}

data "talos_machine_configuration" "this" {
  count = phaser_sequential.this.phase == "running" ? 1 : 0

  cluster_name     = var.kubernetes.cluster.name
  cluster_endpoint = "https://127.0.0.1:7445"
  machine_type     = var.node.type
  machine_secrets  = var.machine_secrets.machine_secrets

  config_patches = flatten([
    templatefile("${path.module}/files/talos-cluster.yaml", {
    }),
    templatefile("${path.module}/files/talos-machine.yaml", {
      hostname      = local.hostname
      install_image = var.image.urls.installer_secureboot
    }),
    templatefile("${path.module}/files/talos-node.yaml", {
      node = merge(
        var.node,
        {
          labels = {
            # kubernetes topology
            "topology.kubernetes.io/region" = var.kubernetes.topology.region
            "topology.kubernetes.io/zone" = coalesce(
              var.kubernetes.topology.zone,
              var.node.target,
            )
            # incus
            "incus.linuxcontainers.org/project" = var.incus.project_name
            "incus.linuxcontainers.org/target"  = var.node.target
          }
        }
      )
    }),
    var.node.type != "controlplane" ? [] : [
      # templatefile("${path.module}/files/talos-controlplane.yaml", {}),
    ],
    var.node.type != "worker" ? [] : [
      # templatefile("${path.module}/files/talos-worker.yaml", {}),
    ],
  ])

  depends_on = [
    incus_instance.this,
    incus_network_zone_record.this,
  ]
}

resource "talos_machine_configuration_apply" "this" {
  count = phaser_sequential.this.phase == "running" ? 1 : 0

  client_configuration        = var.machine_secrets.client_configuration
  node                        = incus_instance.this.ipv4_address
  machine_configuration_input = data.talos_machine_configuration.this[0].machine_configuration

  depends_on = [
    data.talos_machine_configuration.this,
  ]
}
