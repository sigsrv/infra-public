locals {
  all_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(var.content) :
    join("/", [
      manifest["apiVersion"],
      manifest["kind"],
      lookup(manifest["metadata"], "namespace", ""),
      manifest["metadata"]["name"]
    ]) => manifest
  }

  namespace_manifests = {
    for key, manifest in local.all_manifests : key => manifest
    if manifest["kind"] == "Namespace"
  }

  manifests = {
    for key, manifest in local.all_manifests : key => manifest
    if manifest["kind"] != "Namespace"
  }
}

resource "kubernetes_manifest" "namespace" {
  for_each = toset(keys(local.namespace_manifests))
  manifest = local.namespace_manifests[each.key]
}

resource "kubernetes_manifest" "this" {
  for_each = toset(keys(local.manifests))
  manifest = local.manifests[each.key]

  depends_on = [
    kubernetes_manifest.namespace,
  ]
}
