module "cluster" {
  source = "../../../shared/modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-p1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
    instance_targets  = ["sigsrv", "sigsrv", "minisrv"]
  }

  talos = {
    version = "v1.9.3"
    controlplane_node = {
      count  = 3
      cpu    = 4
      memory = "8GiB"
    }
    worker_node = {
      count  = 3
      cpu    = 4
      memory = "4GiB"
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

    metrics_server = {
      enabled = true
    }

    registry = {
      enabled = true
    }

    rook_ceph = {
      enabled = true
    }

    tailscale = {
      enabled = true
    }

    openbao = {
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
