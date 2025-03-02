resource "kubernetes_namespace" "this" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "this" {
  name       = "argocd"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd.version

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.admin.bcrypt_hash
  }

  dynamic "set" {
    for_each = data.http.keybase
    iterator = keybase

    content {
      name  = "configs.gpg.keys.${keybase.key}"
      value = keybase.value.response_body
    }
  }

  set {
    name  = "configs.credentialTemplates.sigsrv-infra.url"
    value = "git@github.com:sigsrv/infra.git"
  }

  set_sensitive {
    name  = "configs.credentialTemplates.sigsrv-infra.sshPrivateKey"
    value = tls_private_key.ssh.private_key_openssh
  }

  depends_on = [
    kubernetes_namespace.this,
  ]
}

module "kubernetes_manifests" {
  source = "../../manifests"
  content = templatefile("${path.module}/argocd.yaml", {
    kubernetes = var.kubernetes
  })

  depends_on = [
    helm_release.this,
  ]
}

data "http" "keybase" {
  for_each = toset(var.argocd.keybase_users)

  url = "https://keybase.io/${each.key}/pgp_keys.asc"
}

data "onepassword_vault" "vault" {
  name = var.onepassword.vault_name
}

resource "random_password" "admin" {
  length  = 40
  special = true
}

resource "onepassword_item" "admin" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.kubernetes.cluster_name}-argocd"

  url      = "https://argocd-${var.kubernetes.cluster_alias}.${var.tailscale.tailnet}"
  username = "admin"
  password = random_password.admin.result
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "onepassword_item" "ssh" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.kubernetes.cluster_name}-argocd-ssh"

  section {
    label = "terraform"

    field {
      label = "public_key"
      value = join(" ", [
        tls_private_key.ssh.public_key_openssh,
        "${var.kubernetes.cluster_name}-argocd-ssh",
      ])
    }
  }
}
