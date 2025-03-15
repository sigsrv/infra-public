module "node" {
  source = "../node"
  count  = var.node.count

  incus      = var.incus
  kubernetes = var.kubernetes

  node = merge(
    var.node,
    {
      name   = "${var.kubernetes.cluster.alias}${var.node.group}${count.index}"
      target = var.kubernetes.topology.targets[count.index % length(var.kubernetes.topology.targets)]
    },
  )
  image           = var.image
  machine_secrets = var.machine_secrets
}
