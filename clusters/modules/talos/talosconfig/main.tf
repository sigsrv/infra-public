resource "local_sensitive_file" "this" {
  filename = "${path.root}/talosconfig"
  content = yamlencode({
    "context" = "talos"
    "contexts" = {
      "talos" = {
        "ca"        = var.machine_secrets.client_configuration.ca_certificate
        "crt"       = var.machine_secrets.client_configuration.client_certificate
        "key"       = var.machine_secrets.client_configuration.client_key
        "endpoints" = [for node in var.controlplane_nodes : node.endpoint]
        "nodes"     = [var.controlplane_nodes[0].endpoint]
      }
    }
  })
}
