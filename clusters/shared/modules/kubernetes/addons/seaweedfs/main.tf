locals {
  seaweedfs_filer = (
    "${var.seaweedfs.seaweed.name}-filer.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8888"
  )
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "seaweedfs"
  }
}

module "this" {
  source = "../../manifests"
  content = templatefile("${path.module}/seaweedfs.yaml", {
    kubernetes = var.kubernetes
    namespace  = kubernetes_namespace.this.metadata[0].name
    seaweedfs  = var.seaweedfs
  })

  depends_on = [
    helm_release.operator,
    kubernetes_namespace.this,
  ]
}
