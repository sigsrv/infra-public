module "cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus_project_name            = "sigsrv-d1"
  incus_network_name            = "sigsrvbr0"
  incus_network_zone_name       = "sigsrv.local"
  incus_instance_targets        = ["minisrv"]
  talos_version                 = "v1.9.3"
  talos_controlplane_node_count = 3
  talos_worker_node_count       = 3
  kubernetes_topology_region    = "apne-kor-se"
  kubernetes_topology_zone      = "apne-kor-se1"
  status                        = var.status
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
