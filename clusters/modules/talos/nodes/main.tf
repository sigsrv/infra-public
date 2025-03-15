locals {
  incus_instance_name_prefix = coalesce(
    var.incus.instance_name_prefix,
    trimprefix(var.incus.project_name, var.incus.project_name_prefix),
  )
}

module "talos_node" {
  source = "../node"
  count  = var.talos_node.count

  incus      = var.incus
  kubernetes = var.kubernetes

  talos_node = merge(
    var.talos_node,
    {
      name   = "${local.incus_instance_name_prefix}${var.talos_node.name}${count.index}"
      target = var.incus.instance_targets[count.index % length(var.incus.instance_targets)]
    },
  )
  talos_image           = var.talos_image
  talos_machine_secrets = var.talos_machine_secrets
}
