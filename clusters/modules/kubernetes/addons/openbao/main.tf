resource "kubernetes_namespace" "this" {
  metadata {
    name = "openbao"
  }
}

resource "helm_release" "this" {
  name       = "openbao"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://openbao.github.io/openbao-helm"
  chart      = "openbao"
  version    = var.openbao.version

  values = [
    yamlencode({
      server = {
        ha = {
          enabled  = true
          replicas = var.openbao.replicas
          raft = {
            enabled   = true
            setNodeId = true
            config    = local.openbao_config
          }
        }
        topologySpreadConstraints = [
          {
            maxSkew           = 1
            topologyKey       = "kubernetes.io/hostname"
            whenUnsatisfiable = "DoNotSchedule"
          },
          {
            maxSkew           = 1
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
          },
          {
            maxSkew           = 1
            topologyKey       = "incus.linuxcontainers.org/target"
            whenUnsatisfiable = "ScheduleAnyway"
          },
        ]
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

module "this" {
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

  retry_join {
    leader_api_addr = "http://openbao-active:8200"
  }
}

service_registration "kubernetes" {}
EOF
}
