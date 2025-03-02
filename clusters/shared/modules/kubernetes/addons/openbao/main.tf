resource "kubernetes_namespace" "this" {
  metadata {
    name = "openbao"
  }
}

resource "helm_release" "this" {
  name       = "openbao"
  repository = "https://openbao.github.io/openbao-helm"
  chart      = "openbao"
  version    = var.openbao.version

  namespace = kubernetes_namespace.this.metadata[0].name

  values = [
    yamlencode({
      server = {
        ha = {
          enabled = true
          raft = {
            enabled   = true
            setNodeId = true
            config    = local.openbao_config
          }
        }
      }
      dataStorage = {
        storageClass = "local-path-protected"
      }
      auditStorage = {
        storageClass = "local-path-protected"
      }
    }),
  ]

  depends_on = [
    kubernetes_namespace.this,
  ]
}

module "kubernetes_manifests" {
  source = "../../manifests"
  content = templatefile("${path.module}/openbao.yaml", {
    kubernetes = var.kubernetes
  })

  depends_on = [
    helm_release.this,
  ]
}

locals {
  openbao_config = <<EOF
ui = true

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}

storage "raft" {
  path = "/openbao/data"
}

service_registration "kubernetes" {}
EOF
}
