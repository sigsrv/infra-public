data "kubectl_file_documents" "this" {
  content = templatefile("${path.module}/registry.yaml", {
    cluster_name  = var.cluster_name
    cluster_alias = var.cluster_alias
  })
}

resource "kubectl_manifest" "this" {
  for_each  = data.kubectl_file_documents.this.manifests
  yaml_body = each.value
}
