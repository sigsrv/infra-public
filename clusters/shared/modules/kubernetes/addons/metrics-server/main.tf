resource "helm_release" "this" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = var.metrics_server.version

  values = [
    yamlencode({})
  ]

  depends_on = [
    module.kubernetes_manifests_kubelet_serving_cert_approver,
  ]
}

data "kubectl_kustomize_documents" "kubelet_serving_cert_approver" {
  target = "${path.module}/kustomize/kubelet-serving-cert-approver"
}

module "kubernetes_manifests_kubelet_serving_cert_approver" {
  source  = "../../manifests"
  content = join("\n---\n", data.kubectl_kustomize_documents.kubelet_serving_cert_approver.documents)
}
