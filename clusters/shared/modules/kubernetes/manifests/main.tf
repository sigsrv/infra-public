resource "kubernetes_manifest" "this" {
  for_each = {
    for manifest in provider::kubernetes::manifest_decode_multi(var.content) :
    join("/", [
      manifest["apiVersion"],
      manifest["kind"],
      lookup(manifest["metadata"], "namespace", ""),
      manifest["metadata"]["name"]
    ]) => manifest
  }

  manifest = each.value
}
