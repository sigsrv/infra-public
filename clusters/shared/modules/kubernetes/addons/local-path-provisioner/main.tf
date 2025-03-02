data "kubectl_kustomize_documents" "this" {
  target = "${path.module}/kustomize"
}

data "kubectl_file_documents" "this" {
  content = join("\n---\n", data.kubectl_kustomize_documents.this.documents)
}

resource "terraform_data" "this" {
  input = data.kubectl_file_documents.this.manifests
}

resource "kubectl_manifest" "this" {
  for_each  = terraform_data.this.output
  yaml_body = each.value
}
