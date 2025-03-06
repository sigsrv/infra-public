resource "kubernetes_namespace" "this" {
  metadata {
    name = "rook-ceph"
    labels = {
      # https://www.talos.dev/v1.9/kubernetes-guides/configuration/ceph-with-rook/
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "operator" {
  name       = "rook-ceph"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
  version    = var.rook_ceph.version

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
  ]
}

resource "helm_release" "cluster" {
  name       = "rook-ceph-cluster"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph-cluster"
  version    = var.rook_ceph.version

  values = [
    yamlencode({
      operatorNamespace = helm_release.operator.namespace
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
    helm_release.operator,
  ]
}
