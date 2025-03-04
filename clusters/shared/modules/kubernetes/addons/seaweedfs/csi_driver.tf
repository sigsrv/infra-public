resource "kubernetes_namespace" "csi_driver" {
  metadata {
    name = "seaweedfs-csi-driver"
    labels = {
      # https://www.talos.dev/v1.9/kubernetes-guides/configuration/ceph-with-rook/#installation
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "csi_driver" {
  name       = "seaweedfs-csi-driver"
  namespace  = kubernetes_namespace.csi_driver.metadata[0].name
  repository = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
  chart      = "seaweedfs-csi-driver"
  version    = var.seaweedfs.csi_driver.version

  values = [
    yamlencode({
      driverName       = var.seaweedfs.csi_driver.name
      storageClassName = "" # disable default storage class
      seaweedfsFiler   = local.seaweedfs_filer
      seaweedfsCsiPlugin = {
        image = var.seaweedfs.csi_driver.image
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.csi_driver,
    module.this,
  ]
}
