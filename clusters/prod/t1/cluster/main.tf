module "incus_project" {
  source = "../../../shared/modules/incus/project"

  incus_project_name = "sigsrv-t1"
  incus_network_name = "sigsrvbr0"
}

module "talos_cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus_project_name            = module.incus_project.incus_project_name
  incus_instance_name_prefix    = trimprefix(module.incus_project.incus_project_name, "sigsrv-")
  incus_network_zone_name       = "sigsrv.local"
  talos_controlplane_node_count = 1
  talos_worker_node_count       = 2
  talos_image                   = module.talos_image
  status                        = var.status

  depends_on = [
    module.incus_project,
    module.talos_image,
  ]
}

module "talos_image" {
  source = "../../../shared/modules/talos/image"

  incus_project_name = module.incus_project.incus_project_name
  talos_version      = "v1.9.3"
}
