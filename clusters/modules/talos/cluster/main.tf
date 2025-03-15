# incus project
module "incus_project" {
  source = "../../incus/project"

  incus = var.incus
}

# incus talos nodes
module "talos_nodes" {
  for_each = var.talos.nodes
  source   = "../nodes"

  incus      = var.incus
  kubernetes = var.kubernetes

  talos_node = merge(
    each.value,
    {
      name = coalesce(each.value.name, each.key)
    },
  )
  talos_image           = module.talos_image
  talos_machine_secrets = talos_machine_secrets.this
}

# incus talos image
module "talos_image" {
  source = "../image"

  incus = var.incus
  talos = var.talos
}

# talos
locals {
  talos_controlplane_nodes = flatten([
    for key, value in module.talos_nodes : [
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
    module.talos_nodes,
  ]
}

module "talosconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../talosconfig"

  talos_controlplane_nodes = local.talos_controlplane_nodes
  talos_machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}

module "kubeconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../kubeconfig"

  talos_controlplane_nodes = local.talos_controlplane_nodes
  talos_machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}
