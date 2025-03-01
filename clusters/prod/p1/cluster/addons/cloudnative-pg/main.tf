resource "kubernetes_namespace" "this" {
  metadata {
    name = "cnpg-system"
  }
}

resource "helm_release" "this" {
  name       = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.23.0"

  namespace = kubernetes_namespace.this.metadata[0].name

  values = [
    yamlencode({})
  ]

  depends_on = [
    kubernetes_namespace.this,
  ]
}
