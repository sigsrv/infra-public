module "cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-p1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
    instance_targets  = ["sigsrv", "sigsrv", "minisrv"]
  }

  talos = {
    version                 = "v1.9.3"
    controlplane_node_count = 3
    worker_node_count       = 6
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
    cluster_name  = "sigsrv-p1"
    cluster_alias = "p1"
    cluster_env   = "prod"
  }

  onepassword = {
    vault_name = "sigsrv-prod"
  }

  addons = {
    argocd = {
      enabled = true
    }

    cert_manager = {
      enabled = true
    }

    cloudnative_pg = {
      enabled = true
    }

    local_path_provisioner = {
      enabled = true
    }

    registry = {
      enabled = true
    }

    tailscale_operator = {
      enabled = true
    }

    openbao = {
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
