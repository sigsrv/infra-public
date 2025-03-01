data "kubectl_kustomize_documents" "this" {
  target = "${path.module}/kustomize"
}

data "kubectl_file_documents" "this" {
  content = join("\n---\n", data.kubectl_kustomize_documents.this.documents)
}

resource "kubectl_manifest" "this" {
  for_each  = data.kubectl_file_documents.this.manifests
  yaml_body = each.value
}
