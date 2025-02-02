locals {
  manifests = merge([
    for _, documents in data.kubectl_file_documents.this : {
      for key, value in documents.manifests : key => value
      if !startswith(key, "/apis/secrets.hashicorp.com/")
    }
  ]...)
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name
  }
}

resource "kubectl_manifest" "this" {
  for_each = local.manifests
  yaml_body = replace(
    each.value,
    "registry-prod.deer-neon.ts.net",
    "registry-t1.deer-neon.ts.net",
  )

  depends_on = [
    kubernetes_namespace.this,
  ]
}

data "kubectl_file_documents" "this" {
  for_each = toset(concat(var.deployments, var.manifests))
  content  = file("${path.module}/langbot/kubernetes/${each.key}.yaml")
}

data "onepassword_vault" "vault" {
  name = var.onepassword_vault
}

data "onepassword_item" "this" {
  for_each = var.onepassword_items

  vault = data.onepassword_vault.vault.uuid
  title = each.value
}

resource "kubernetes_secret" "this" {
  for_each = var.onepassword_items

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    for field in data.onepassword_item.this[each.key].section[0].field :
    field.label => field.value
  }
}
