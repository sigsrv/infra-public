module "talos_cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus_project_name            = "sigsrv-t1"
  incus_network_name            = "sigsrvbr0"
  incus_network_zone_name       = "sigsrv.local"
  talos_version                 = "v1.9.3"
  talos_controlplane_node_count = 1
  talos_worker_node_count       = 2
  status                        = var.status
}
