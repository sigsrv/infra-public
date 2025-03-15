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
    nodes = {
      controlplane = {
        count = 1
      }
      worker = {
        count = 1
      }
    }
  }

  kubernetes = {
    cluster_name    = "sigsrv-d1"
    cluster_alias   = "d1"
    cluster_env     = "dev"
    topology_region = "apne-kor-se"
    topology_zone   = "apne-kor-se1"
  }
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
