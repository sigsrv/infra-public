resource "vault_pki_secret_backend_role" "cockroachdb-node" {
  backend     = module.vault_app_cockroachdb_pki.vault_pki_path
  name        = "${local.cockroachdb_cluster_name}-node"
  key_type    = "ec"
  key_bits    = 384
  ttl         = 31536000 # 1y
  server_flag = true
  client_flag = true

  allow_any_name              = true # TODO: remove this
  allow_bare_domains          = true
  allow_ip_sans               = true
  allow_localhost             = true
  allow_wildcard_certificates = true
  allowed_domains = [
    "localhost",
    "${local.cockroachdb_cluster_name}-public",
    "${local.cockroachdb_cluster_name}-public.${local.kubernetes_app_namespace}",
    "${local.cockroachdb_cluster_name}-public.${local.kubernetes_app_namespace}.svc.cluster.local",
    "*.${local.cockroachdb_cluster_name}",
    "*.${local.cockroachdb_cluster_name}.${local.kubernetes_app_namespace}",
    "*.${local.cockroachdb_cluster_name}.${local.kubernetes_app_namespace}.svc.cluster.local",
  ]
}

resource "kubernetes_manifest" "cockroachdb-nodes-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "${vault_pki_secret_backend_role.cockroachdb-node.name}-issuer"
      namespace = local.kubernetes_app_namespace
    }
    spec = {
      vault = {
        server = local.vault_internal_url
        path   = "${module.vault_app_cockroachdb_pki.vault_pki_path}/sign/${vault_pki_secret_backend_role.cockroachdb-node.name}"
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

resource "vault_pki_secret_backend_cert" "cockroachdb-node" {
  backend              = module.vault_app_cockroachdb_pki.vault_pki_path
  name                 = vault_pki_secret_backend_role.cockroachdb-node.name
  common_name          = "node"
  alt_names            = vault_pki_secret_backend_role.cockroachdb-node.allowed_domains
  exclude_cn_from_sans = true
  ttl                  = 31536000 # 1y
}

resource "kubernetes_manifest" "cockroachdb-node" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.cockroachdb_cluster_name}-${vault_pki_secret_backend_cert.cockroachdb-node.common_name}"
      namespace = local.kubernetes_app_namespace
    }
    spec = {
      secretName = "${local.cockroachdb_cluster_name}-${vault_pki_secret_backend_cert.cockroachdb-node.common_name}"
      issuerRef = {
        name = kubernetes_manifest.cockroachdb-nodes-issuer.manifest.metadata.name
      }
      commonName  = vault_pki_secret_backend_cert.cockroachdb-node.common_name
      dnsNames    = vault_pki_secret_backend_role.cockroachdb-node.allowed_domains
      ipAddresses = ["127.0.0.1"]
      privateKey = {
        algorithm = "ECDSA"
        size      = 384
      }
    }
  }
}
