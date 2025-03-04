data "kubectl_kustomize_documents" "this" {
  target = var.target
}

locals {
  content = join("\n---\n", data.kubectl_kustomize_documents.this.documents)
  manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(local.content) :
    join("/", [
      manifest["apiVersion"],
      manifest["kind"],
      lookup(manifest["metadata"], "namespace", ""),
      manifest["metadata"]["name"]
    ]) => manifest
  }
}

resource "kubernetes_manifest" "this" {
  for_each = toset(keys(local.manifests))
  manifest = local.manifests[each.key]
}
