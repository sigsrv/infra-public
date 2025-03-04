locals {
  manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(var.content) :
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
