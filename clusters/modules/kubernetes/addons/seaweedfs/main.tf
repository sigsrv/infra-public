resource "kubernetes_namespace" "this" {
  metadata {
    name = "seaweedfs"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "cluster" {
  name       = "seaweedfs"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://seaweedfs.github.io/seaweedfs/helm"
  chart      = "seaweedfs"
  version    = var.seaweedfs.version

  values = [
    file("${path.module}/seaweedfs-values.yaml"),
  ]

  depends_on = [
    kubernetes_namespace.this,
  ]
}

resource "helm_release" "csi_driver" {
  count      = var.seaweedfs.csi_driver.enabled ? 1 : 0
  name       = "seaweedfs-csi-driver"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
  chart      = "seaweedfs-csi-driver"
  version    = var.seaweedfs.csi_driver.version

  values = [
    file("${path.module}/seaweedfs-csi-driver-values.yaml"),
  ]

  depends_on = [
    helm_release.cluster,
  ]
}

resource "kubernetes_storage_class" "storage_class_protected" {
  count = var.seaweedfs.csi_driver.enabled ? 1 : 0

  metadata {
    name = "seaweedfs-storage-protected"
  }

  storage_provisioner    = "seaweedfs-csi-driver"
  allow_volume_expansion = true
  reclaim_policy         = "Retain"

  depends_on = [
    helm_release.csi_driver,
  ]
}
