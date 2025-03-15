module "incus_project" {
  source = "../../incus/project"

  incus = var.incus
}

module "nodes" {
  for_each = var.kubernetes.nodes
  source   = "../nodes"

  incus      = var.incus
  kubernetes = var.kubernetes

  node = merge(
    each.value,
    {
      group = coalesce(each.value.group, each.key)
    },
  )
  image           = module.image
  machine_secrets = talos_machine_secrets.this
}

module "image" {
  source = "../image"

  incus = var.incus
  talos = var.talos
}

locals {
  talos_controlplane_nodes = flatten([
    for key, value in module.nodes : [
      for node in value.node : node
      if node.phase == "running"
    ]
    if value.type == "controlplane"
  ])
}

resource "talos_machine_secrets" "this" {}

resource "talos_machine_bootstrap" "this" {
  count = length(local.talos_controlplane_nodes) > 0 ? 1 : 0

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.talos_controlplane_nodes[0].ipv4_address

  depends_on = [
    module.nodes,
  ]
}

module "talosconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../talosconfig"

  controlplane_nodes = local.talos_controlplane_nodes
  machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}

module "kubeconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../kubeconfig"

  controlplane_nodes = local.talos_controlplane_nodes
  machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}
