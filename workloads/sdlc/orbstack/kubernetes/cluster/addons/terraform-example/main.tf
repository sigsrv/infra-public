resource "kubernetes_namespace" "seaweedfs" {
  metadata {
    name = "seaweedfs"
  }
}

# https://artifacthub.io/packages/helm/cert-manager/cert-manager
resource "helm_release" "seaweedfs-csi" {
  repository = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
  chart      = "seaweedfs-csi-driver"
  name       = "seaweedfs-csi"

  namespace = "seaweedfs"

  set {
    name  = "seaweedfsFiler"
    value = "seaweedfs-server.seaweedfs.svc.cluster.local:8888"
  }

  depends_on = [
    kubernetes_namespace.seaweedfs,
  ]
}
