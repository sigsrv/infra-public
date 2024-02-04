# https://deployment.properties/posts/devsecops/cockroachdb-vault-pki-certmanager/#checkpoint
# https://developer.hashicorp.com/vault/docs/secrets/pki/quick-start-root-ca
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_set_signed
resource "vault_pki_secret_backend_role" "cockroachdb-client" {
  backend     = module.vault_app_cockroachdb_pki.vault_pki_path
  name        = "${local.cockroachdb_cluster_name}-client"
  key_type    = "ec"
  key_bits    = 384
  ttl         = 31536000 # 1y
  server_flag = false
  client_flag = true

  allow_any_name = true # TODO: remove this
}

resource "kubernetes_manifest" "cockroachdb-client-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "${vault_pki_secret_backend_role.cockroachdb-client.name}-issuer"
      namespace = local.kubernetes_app_namespace
    }
    spec = {
      vault = {
        server = local.vault_internal_url
        path   = "${module.vault_app_cockroachdb_pki.vault_pki_path}/sign/${vault_pki_secret_backend_role.cockroachdb-client.name}"
        auth = {
          kubernetes = {
            mountPath = "/v1/auth/kubernetes"
            role      = vault_kubernetes_auth_backend_role.cockroachdb-issuer.role_name
            secretRef = {
              name = kubernetes_secret.cockroachdb-issuer-token.metadata[0].name
              key  = "token"
            }
          }
        }
      }
    }
  }
}

resource "vault_pki_secret_backend_cert" "cockroachdb-root" {
  backend              = module.vault_app_cockroachdb_pki.vault_pki_path
  name                 = vault_pki_secret_backend_role.cockroachdb-client.name
  common_name          = "root"
  exclude_cn_from_sans = true
  ttl                  = 31536000 # 1y
}

resource "kubernetes_manifest" "cockroachdb-root" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.cockroachdb_cluster_name}-${vault_pki_secret_backend_cert.cockroachdb-root.common_name}"
      namespace = local.kubernetes_app_namespace
    }
    spec = {
      secretName = "${local.cockroachdb_cluster_name}-${vault_pki_secret_backend_cert.cockroachdb-root.common_name}"
      issuerRef = {
        name = kubernetes_manifest.cockroachdb-client-issuer.manifest.metadata.name
      }
      commonName = vault_pki_secret_backend_cert.cockroachdb-root.common_name
      privateKey = {
        algorithm = "ECDSA"
        size      = 384
      }
    }
  }
}
