resource "kubernetes_namespace" "this" {
  metadata {
    name = "openbao"
  }
}

resource "helm_release" "this" {
  name       = "openbao"
  repository = "https://openbao.github.io/openbao-helm"
  chart      = "openbao"

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

data "kubectl_file_documents" "this" {
  content = templatefile("${path.module}/openbao.yaml", {
    cluster_name  = var.cluster_name
    cluster_alias = var.cluster_alias
  })
}

resource "terraform_data" "this" {
  input = data.kubectl_file_documents.this.manifests
}

resource "kubectl_manifest" "this" {
  for_each  = terraform_data.this.output
  yaml_body = each.value
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
