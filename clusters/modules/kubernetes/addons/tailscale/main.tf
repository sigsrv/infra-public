resource "kubernetes_namespace" "this" {
  metadata {
    name = "tailscale"
  }
}

resource "helm_release" "operator" {
  name       = "tailscale-operator"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = var.tailscale.version

  values = [
    yamlencode({
      operatorConfig = {
        hostname    = "${var.kubernetes.cluster.name}-tailscale-operator"
        defaultTags = join(",", ["tag:${var.kubernetes.cluster.name}-tailscale-operator"])
      }
      proxyConfig = {
        defaultTags = join(",", ["tag:${var.kubernetes.cluster.name}-tailscale-service"])
        apiServerProxyConfig = {
          mode = true
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_secret.operator,
  ]
}

resource "kubernetes_secret" "operator" {
  metadata {
    name      = "operator-oauth"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    client_id     = data.onepassword_item.operator.username
    client_secret = data.onepassword_item.operator.password
  }

  depends_on = [
    kubernetes_namespace.this,
  ]
}

data "onepassword_vault" "vault" {
  name = var.onepassword.vault_name
}

data "onepassword_item" "operator" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.kubernetes.cluster.name}-tailscale-operator"
}
