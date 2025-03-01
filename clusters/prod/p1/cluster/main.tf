module "talos_cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus_project_name            = "sigsrv-p1"
  incus_network_name            = "sigsrvbr0"
  incus_network_zone_name       = "sigsrv.local"
  incus_instance_targets        = ["sigsrv", "sigsrv", "minisrv"]
  talos_version                 = "v1.9.3"
  talos_controlplane_node_count = 3
  talos_worker_node_count       = 6
  status                        = var.status
}
