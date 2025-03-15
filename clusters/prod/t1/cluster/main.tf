module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-t1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
    instance_targets  = ["sigsrv"]
  }

  talos = {
    version = "v1.9.3"
    nodes = {
      controlplane = {
        count = 1
      }
      worker = {
        count = 2
      }
    }
  }

  kubernetes = {
    cluster_name    = "sigsrv-t1"
    cluster_alias   = "t1"
    cluster_env     = "prod"
    topology_region = "apne-kor-se"
    topology_zone   = "apne-kor-se1"
  }
}

module "addons" {
  source = "../../../modules/kubernetes/addons"
  count  = module.cluster.ready ? 1 : 0

  kubernetes = module.cluster.config.kubernetes

  onepassword = {
    vault_name = "sigsrv-prod"
  }

  addons = {
    local_path_provisioner = {
      enabled = true
    }

    registry = {
      enabled = true
    }

    tailscale_operator = {
      enabled = true
    }
  }

  depends_on = [
    module.cluster
  ]
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
