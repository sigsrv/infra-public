locals {
  original_cluster_name = "sigsrv-prod"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "tailscale"
  }
}

resource "helm_release" "this" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.78.3"

  namespace = kubernetes_namespace.this.metadata[0].name

  values = [
    yamlencode({
      operatorConfig = {
        hostname    = "${local.original_cluster_name}-tailscale-operator"
        defaultTags = join(",", ["tag:${local.original_cluster_name}-tailscale-operator"])
      }
      proxyConfig = {
        defaultTags = join(",", ["tag:${local.original_cluster_name}-tailscale-service"])
        apiServerProxyConfig = {
          mode = true
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_secret.this,
  ]
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "operator-oauth"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    client_id     = data.onepassword_item.this.username
    client_secret = data.onepassword_item.this.password
  }

  depends_on = [
    kubernetes_namespace.this,
  ]
}

data "onepassword_vault" "vault" {
  name = "sigsrv-prod"
}

data "onepassword_item" "this" {
  vault = data.onepassword_vault.vault.uuid
  title = "${local.original_cluster_name}-tailscale-operator"
}
