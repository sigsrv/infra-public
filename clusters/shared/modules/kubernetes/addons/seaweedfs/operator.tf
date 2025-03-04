resource "kubernetes_namespace" "operator" {
  metadata {
    name = "seaweedfs-operator-system"
  }
}

resource "helm_release" "operator" {
  name       = "seaweedfs-operator"
  namespace  = kubernetes_namespace.operator.metadata[0].name
  repository = "https://seaweedfs.github.io/seaweedfs-operator/helm"
  chart      = "seaweedfs-operator"
  version    = var.seaweedfs.operator.version

  values = [
    yamlencode({
      image = {
        registry   = "ghcr.io/seaweedfs"
        repository = "seaweedfs-operator"
        tag        = "latest"
      }
      serviceMonitor = {
        enabled = false
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.operator,
  ]

  wait = false
}
