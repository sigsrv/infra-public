module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-d1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
    instance_targets  = ["minisrv"]
  }

  talos = {
    version = "v1.9.3"
    controlplane_node = {
      count = 3
    }
    worker_node = {
      count = 3
    }
  }

  kubernetes = {
    topology_region = "apne-kor-se"
    topology_zone   = "apne-kor-se1"
  }

  status = var.status
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
