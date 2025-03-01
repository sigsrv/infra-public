module "talos_cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus_project_name            = "sigsrv-d1"
  incus_network_name            = "sigsrvbr0"
  incus_network_zone_name       = "sigsrv.local"
  incus_instance_targets        = ["minisrv"]
  talos_version                 = "v1.9.3"
  talos_controlplane_node_count = 3
  talos_worker_node_count       = 3
  status                        = var.status
}
