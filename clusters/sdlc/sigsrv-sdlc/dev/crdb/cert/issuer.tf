resource "kubernetes_service_account" "cockroachdb-issuer" {
  metadata {
    name      = "${local.cockroachdb_cluster_name}-issuer"
    namespace = local.kubernetes_app_namespace
  }
}

resource "kubernetes_secret" "cockroachdb-issuer-token" {
  type = "kubernetes.io/service-account-token"

  metadata {
    name      = "${kubernetes_service_account.cockroachdb-issuer.metadata[0].name}-token"
    namespace = local.kubernetes_app_namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.cockroachdb-issuer.metadata[0].name
    }
  }
}

resource "vault_kubernetes_auth_backend_role" "cockroachdb-issuer" {
  backend                          = "kubernetes"
  role_name                        = "app-${local.kubernetes_cluster_name}-${local.kubernetes_app_namespace}-${local.kubernetes_app_name}-${kubernetes_service_account.cockroachdb-issuer.metadata[0].name}"
  bound_service_account_names      = [kubernetes_service_account.cockroachdb-issuer.metadata[0].name]
  bound_service_account_namespaces = [local.kubernetes_app_namespace]
  token_policies                   = [vault_policy.cockroachdb-issuer.name]
}

resource "vault_policy" "cockroachdb-issuer" {
  name   = "app/${local.kubernetes_cluster_name}/${local.kubernetes_app_namespace}/${local.kubernetes_app_name}/cockroachdb/cockroachdb-issuer"
  policy = <<EOF
path "${module.vault_app_cockroachdb_pki.vault_pki_path}/sign/${vault_pki_secret_backend_role.cockroachdb-node.name}" {
    capabilities = ["create", "update"]
}

path "${module.vault_app_cockroachdb_pki.vault_pki_path}/issue/${vault_pki_secret_backend_role.cockroachdb-node.name}" {
    capabilities = ["create"]
}

path "${module.vault_app_cockroachdb_pki.vault_pki_path}/sign/${vault_pki_secret_backend_role.cockroachdb-client.name}" {
    capabilities = ["create", "update"]
}

path "${module.vault_app_cockroachdb_pki.vault_pki_path}/issue/${vault_pki_secret_backend_role.cockroachdb-client.name}" {
    capabilities = ["create"]
}
EOF
}
