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

module "talos_controlplane_node" {
  count  = var.talos.controlplane_node.count
  source = "../node"

  incus      = var.incus
  kubernetes = var.kubernetes

  talos_image           = module.talos_image
  talos_machine_secrets = talos_machine_secrets.this
  talos_node = {
    type   = "controlplane"
    index  = count.index
    name   = "${local.incus_instance_name_prefix}c${count.index}"
    target = var.incus.instance_targets[count.index % length(var.incus.instance_targets)]
    cpu    = var.talos.controlplane_node.cpu
    memory = var.talos.controlplane_node.memory
  }
}

module "talos_worker_node" {
  count  = var.talos.worker_node.count
  source = "../node"

  incus      = var.incus
  kubernetes = var.kubernetes

  talos_image           = module.talos_image
  talos_machine_secrets = talos_machine_secrets.this
  talos_node = {
    type   = "worker"
    index  = count.index
    name   = "${local.incus_instance_name_prefix}w${count.index}"
    target = var.incus.instance_targets[count.index % length(var.incus.instance_targets)]
    cpu    = var.talos.worker_node.cpu
    memory = var.talos.worker_node.memory
  }
}

# incus talos image
module "talos_image" {
  source = "../image"

  incus = var.incus
  talos = var.talos
}

# talos
locals {
  controlplane_node_is_running = alltrue([
    for node in module.talos_controlplane_node : node.phase == "running"
  ])
}

resource "talos_machine_secrets" "this" {}

resource "talos_machine_bootstrap" "this" {
  count = local.controlplane_node_is_running ? 1 : 0

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = module.talos_controlplane_node[0].ipv4_address

  depends_on = [
    module.talos_controlplane_node,
  ]
}

module "talosconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../talosconfig"

  talos_controlplane_nodes = module.talos_controlplane_node
  talos_machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}

module "kubeconfig" {
  count  = length(talos_machine_bootstrap.this[*])
  source = "../kubeconfig"

  talos_controlplane_nodes = module.talos_controlplane_node
  talos_machine_secrets    = talos_machine_secrets.this

  depends_on = [talos_machine_bootstrap.this]
}
