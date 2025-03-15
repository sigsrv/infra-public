resource "kubernetes_namespace" "this" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "this" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager.version

  values = [
    yamlencode({
      installCRDs = true
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
  ]
}
