resource "kubernetes_namespace" "this" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "this" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace = kubernetes_namespace.this.metadata[0].name

  values = [
    yamlencode({
      crds = {
        install = false
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(onepassword_item.this.password)
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
    kubectl_manifest.kustomize,
  ]
}

data "kubectl_file_documents" "this" {
  content = templatefile("${path.module}/argocd.yaml", {
    cluster_name  = var.cluster_name
    cluster_alias = var.cluster_alias
    cluster_env   = var.cluster_env
  })
}

resource "kubectl_manifest" "this" {
  for_each  = data.kubectl_file_documents.this.manifests
  yaml_body = each.value

  depends_on = [
    helm_release.this,
  ]
}

data "http" "keybase" {
  for_each = toset(["ecmaxp"])

  url = "https://keybase.io/${each.key}/pgp_keys.asc"
}


data "kubectl_kustomize_documents" "kustomize" {
  target = "${path.module}/kustomize"
}

data "kubectl_file_documents" "kustomize" {
  content = join("\n---\n", data.kubectl_kustomize_documents.kustomize.documents)
}

resource "kubectl_manifest" "kustomize" {
  for_each  = data.kubectl_file_documents.kustomize.manifests
  yaml_body = each.value
}

data "onepassword_vault" "vault" {
  name = "sigsrv-prod"
}

resource "onepassword_item" "this" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.cluster_name}-argocd"

  url      = "https://argocd-${var.cluster_alias}.deer-neon.ts.net"
  username = "admin"

  password_recipe {
    length  = 40
    digits  = true
    letters = true
    symbols = true
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "onepassword_item" "ssh" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.cluster_name}-argocd-ssh"

  section {
    label = "terraform"

    field {
      label = "public_key"
      value = join(" ", [
        tls_private_key.ssh.public_key_openssh,
        "${var.cluster_name}-argocd-ssh",
      ])
    }
  }
}
