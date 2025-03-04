module "this" {
  source = "../../manifests"
  content = templatefile("${path.module}/registry.yaml", {
    kubernetes = var.kubernetes
    registry   = var.registry
  })
}
