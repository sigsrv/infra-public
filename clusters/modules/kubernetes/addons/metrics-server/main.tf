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
    module.kubelet_serving_cert_approver,
  ]
}

module "kubelet_serving_cert_approver" {
  source = "../../kustomize"
  target = "${path.module}/kustomize/kubelet-serving-cert-approver"
}
