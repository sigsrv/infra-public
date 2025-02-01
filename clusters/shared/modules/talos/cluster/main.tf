# incus instances
resource "incus_instance" "this" {
  for_each = merge(
    {
      for i in range(var.talos_controlplane_node_count) :
      "${var.incus_instance_name_prefix}c${i}" => {
        type = "controlplane"
      }
    },
    {
      for i in range(var.talos_worker_node_count) :
      "${var.incus_instance_name_prefix}w${i}" => {
        type = "worker"
      }
    },
  )

  project = var.incus_project_name
  name    = each.key
  type    = "virtual-machine"
  running = var.status != "ready"

  config = {
    "user.talos.machine.type" = each.value.type
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
      "source"        = var.talos_image.incus_iso_volume
      "boot.priority" = 10
    }
  }
}

locals {
  all_nodes = {
    for key, value in incus_instance.this : key => value
    if value.running
  }
  controlplane_nodes = {
    for key, value in incus_instance.this : key => value
    if value.config["user.talos.machine.type"] == "controlplane" && value.running
  }
  controlplane_node = try([for _, node in local.controlplane_nodes : node][0], null)
}

# incus network zone records
resource "incus_network_zone_record" "this" {
  for_each = local.all_nodes

  zone = var.incus_network_zone_name
  name = each.value.name

  entry {
    type  = "A"
    value = each.value.ipv4_address
    ttl   = 60
  }
}

locals {
  node_domains = {
    for key, value in local.all_nodes :
    key => "${incus_network_zone_record.this[key].name}.${incus_network_zone_record.this[key].zone}"
  }
}

# talos
resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "this" {
  for_each = local.all_nodes

  cluster_name     = var.incus_project_name
  cluster_endpoint = "https://127.0.0.1:7445"
  machine_type     = each.value.config["user.talos.machine.type"]
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = flatten([
    templatefile("${path.module}/files/talos-cluster.yaml", {
    }),
    templatefile("${path.module}/files/talos-machine.yaml", {
      hostname      = "${each.value.name}.${var.incus_network_zone_name}"
      install_image = var.talos_image.urls.installer_secureboot
    }),
    each.value.config["user.talos.machine.type"] != "controlplane" ? [] : [
      # templatefile("${path.module}/files/talos-controlplane.yaml", {}),
    ],
    each.value.config["user.talos.machine.type"] != "worker" ? [] : [
      # templatefile("${path.module}/files/talos-worker.yaml", {}),
    ],
  ])
}

resource "talos_machine_configuration_apply" "this" {
  for_each = local.all_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  node                        = each.value.ipv4_address
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
}

resource "talos_machine_bootstrap" "this" {
  count = var.status == "ready" ? 0 : 1

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_node.ipv4_address

  depends_on = [
    talos_machine_configuration_apply.this
  ]
}

# talosconfig
resource "local_sensitive_file" "talosconfig" {
  count = var.status == "ready" ? 0 : 1

  filename = "${path.root}/talosconfig"
  content = yamlencode({
    "context" = "talos"
    "contexts" = {
      "talos" = {
        "ca"  = talos_machine_secrets.this.client_configuration.ca_certificate
        "crt" = talos_machine_secrets.this.client_configuration.client_certificate
        "key" = talos_machine_secrets.this.client_configuration.client_key
        "endpoints" = [
          for _, node in local.controlplane_nodes : local.node_domains[node.name]
        ]
        "nodes" = [local.node_domains[local.controlplane_node.name]]
      }
    }
  })

  depends_on = [
    talos_machine_configuration_apply.this,
  ]
}

# kubeconfig
resource "talos_cluster_kubeconfig" "kubeconfig" {
  count = var.status == "ready" ? 0 : 1

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_node.ipv4_address

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

resource "local_sensitive_file" "kubeconfig" {
  count = var.status == "ready" ? 0 : 1

  filename = "${path.root}/kubeconfig"
  content = replace(
    talos_cluster_kubeconfig.kubeconfig[0].kubeconfig_raw,
    "https://127.0.0.1:7445",
    "https://${local.node_domains[local.controlplane_node.name]}:6443",
  )

  depends_on = [
    talos_cluster_kubeconfig.kubeconfig,
  ]
}
