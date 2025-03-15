resource "local_sensitive_file" "this" {
  filename = "${path.root}/talosconfig"
  content = yamlencode({
    "context" = "talos"
    "contexts" = {
      "talos" = {
        "ca"        = var.talos_machine_secrets.client_configuration.ca_certificate
        "crt"       = var.talos_machine_secrets.client_configuration.client_certificate
        "key"       = var.talos_machine_secrets.client_configuration.client_key
        "endpoints" = [for node in var.talos_controlplane_nodes : node.endpoint]
        "nodes"     = [var.talos_controlplane_nodes[0].endpoint]
      }
    }
  })
}
