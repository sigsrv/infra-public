data "kubectl_kustomize_documents" "this" {
  target = "${path.module}/kustomize"
}

module "kubernetes_manifests" {
  source  = "../../manifests"
  content = join("\n---\n", data.kubectl_kustomize_documents.this.documents)
}
