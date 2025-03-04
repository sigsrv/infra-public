# incus project
module "incus_project" {
  source = "../../incus/project"

  incus = var.incus
}

# incus instances
locals {
  incus_instance_name_prefix = coalesce(
    var.incus.instance_name_prefix,
    trimprefix(var.incus.project_name, var.incus.project_name_prefix),
  )
}

resource "incus_instance" "this" {
  for_each = merge(
    {
      for i in range(var.talos.controlplane_node.count) :
      "${local.incus_instance_name_prefix}c${i}" => {
        type   = "controlplane"
        index  = i
        target = var.incus.instance_targets[i % length(var.incus.instance_targets)]
        cpu    = var.talos.controlplane_node.cpu
        memory = var.talos.controlplane_node.memory
      }
    },
    {
      for i in range(var.talos.worker_node.count) :
      "${local.incus_instance_name_prefix}w${i}" => {
        type   = "worker"
        index  = i
        target = var.incus.instance_targets[i % length(var.incus.instance_targets)]
        cpu    = var.talos.worker_node.cpu
        memory = var.talos.worker_node.memory
      }
    },
  )

  project = var.incus.project_name
  name    = each.key
  type    = "virtual-machine"
  target  = each.value.target
  running = var.status != "ready"

  config = {
    "limits.cpu"              = each.value.cpu
    "limits.memory"           = each.value.memory
    "user.talos.machine.type" = each.value.type
    "user.incus.hostname"     = "${each.key}.${var.incus.network_zone_name}"
    "user.incus.target"       = each.value.target
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
      "source"        = module.talos_image.incus_iso_volume
      "boot.priority" = 10
    }
  }

  depends_on = [
    module.incus_project,
    module.talos_image,
  ]
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

# incus talos image
module "talos_image" {
  source = "../image"

  incus = var.incus
  talos = var.talos
}

# incus network zone records
resource "incus_network_zone_record" "this" {
  for_each = local.all_nodes

  zone = var.incus.network_zone_name
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

  cluster_name     = var.incus.project_name
  cluster_endpoint = "https://127.0.0.1:7445"
  machine_type     = each.value.config["user.talos.machine.type"]
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = flatten([
    templatefile("${path.module}/files/talos-cluster.yaml", {
    }),
    templatefile("${path.module}/files/talos-machine.yaml", {
      hostname = each.value.config["user.incus.hostname"]
      node_labels = {
        # kubernetes topology
        "topology.kubernetes.io/region" = var.kubernetes.topology_region
        "topology.kubernetes.io/zone" = coalesce(
          var.kubernetes.topology_zone,
          each.value.config["user.incus.target"],
        )
        # incus
        "incus.linuxcontainers.org/cluster" = var.incus.cluster_name
        "incus.linuxcontainers.org/project" = var.incus.project_name
        "incus.linuxcontainers.org/target"  = each.value.config["user.incus.target"]
      }
      node_annotations = {
      }
      node_taints = {
      }
      install_image = module.talos_image.urls.installer_secureboot
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
