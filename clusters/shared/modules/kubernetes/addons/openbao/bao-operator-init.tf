data "kubernetes_resource" "statefulset" {
  api_version = "apps/v1"
  kind        = "StatefulSet"

  metadata {
    name      = helm_release.this.name
    namespace = helm_release.this.namespace
  }

  depends_on = [
    helm_release.this,
  ]
}

resource "kubernetes_job" "init" {
  metadata {
    name      = "${helm_release.this.name}-init"
    namespace = helm_release.this.namespace
  }

  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.init.metadata[0].name

        container {
          name        = "${helm_release.this.name}-init"
          image       = data.kubernetes_resource.statefulset.object.spec.template.spec.containers[0].image
          working_dir = "/root/${helm_release.this.name}"
          command     = ["/bin/sh", "-ec"]
          args = [<<EOF
set -euxo pipefail

if bao operator init -status; then
  echo "bao operator already initialized"
  exit 0
fi

apk add kubectl

bao operator init \
    -pgp-keys=${join(",", var.openbao.pgp_keys)} \
    -root-token-pgp-key=${var.openbao.root_token_pgp_key} \
    -key-shares=${var.openbao.key_shares} \
    -key-threshold=${var.openbao.key_threshold} \
    -format=json > /tmp/machine-init.json

kubectl create secret generic \
  "${helm_release.this.name}-init" \
  --from-file=machine-init.json=/tmp/machine-init.json
EOF
          ]

          env {
            name  = "BAO_ADDR"
            value = "http://${helm_release.this.name}-0.${helm_release.this.name}-internal.${helm_release.this.namespace}.svc.cluster.local:8200"
          }

          volume_mount {
            name       = "${helm_release.this.name}-init"
            mount_path = "/root/${helm_release.this.name}"
          }
        }

        volume {
          name = "${helm_release.this.name}-init"
          config_map {
            name = kubernetes_config_map.init.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_role_binding.init,
    kubernetes_config_map.init,
  ]
}

resource "kubernetes_service_account" "init" {
  metadata {
    name      = "${helm_release.this.name}-init"
    namespace = helm_release.this.namespace
  }

  depends_on = [
    helm_release.this,
  ]
}

resource "kubernetes_role" "init" {
  metadata {
    name      = "${helm_release.this.name}-init"
    namespace = helm_release.this.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }

  depends_on = [
    helm_release.this,
  ]
}

resource "kubernetes_role_binding" "init" {
  metadata {
    name      = kubernetes_role.init.metadata[0].name
    namespace = kubernetes_role.init.metadata[0].namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.init.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.init.metadata[0].name
    namespace = kubernetes_service_account.init.metadata[0].namespace
  }

  depends_on = [
    kubernetes_role.init,
    kubernetes_service_account.init,
  ]
}

resource "kubernetes_config_map" "init" {
  metadata {
    name      = "${helm_release.this.name}-init"
    namespace = helm_release.this.namespace
  }

  data = terraform_data.pgp_keys.output

  depends_on = [
    helm_release.this,
  ]
}

resource "terraform_data" "pgp_keys" {
  input = {
    for pgp_key in toset(concat(var.openbao.pgp_keys, [var.openbao.root_token_pgp_key])) :
    pgp_key => sensitive(file("${path.module}/pgp-keys/${pgp_key}"))
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for pgp_key in toset(concat(var.openbao.pgp_keys, [var.openbao.root_token_pgp_key])) :
        fileexists("${path.module}/pgp-keys/${pgp_key}")
      ])
      error_message = "one or more PGP keys are missing"
    }
  }
}
