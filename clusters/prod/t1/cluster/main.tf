module "cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-t1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
    instance_targets  = ["minisrv"]
  }

  talos = {
    version = "v1.9.3"
    controlplane_node = {
      count = 1
    }
    worker_node = {
      count = 2
    }
  }

  kubernetes = {
    topology_region = "apne-kor-se"
    topology_zone   = "apne-kor-se1"
  }

  status = var.status
}

module "addons" {
  source = "../../../shared/modules/kubernetes/addons"

  kubernetes = {
    cluster_name  = "sigsrv-t1"
    cluster_alias = "t1"
    cluster_env   = "prod"
  }

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

  status = var.status

  depends_on = [
    module.cluster
  ]
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
