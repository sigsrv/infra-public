data "kubectl_file_documents" "this" {
  content = templatefile("${path.module}/registry.yaml", {
    kubernetes = var.kubernetes
    registry   = var.registry
  })
}

resource "terraform_data" "this" {
  input = data.kubectl_file_documents.this.manifests
}

resource "kubectl_manifest" "this" {
  for_each  = terraform_data.this.output
  yaml_body = each.value
}
