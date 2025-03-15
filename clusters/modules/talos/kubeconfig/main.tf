resource "local_sensitive_file" "this" {
  filename = "${path.root}/kubeconfig"
  content = replace(
    talos_cluster_kubeconfig.this.kubeconfig_raw,
    "https://127.0.0.1:7445",
    "https://${var.controlplane_nodes[0].endpoint}:6443",
  )
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.machine_secrets.client_configuration
  node                 = var.controlplane_nodes[0].ipv4_address
}
