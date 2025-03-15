module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-t1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
  }

  talos = {
    version = "v1.9.3"
  }

  kubernetes = {
    cluster = {
      name  = "sigsrv-t1"
      alias = "t1"
      env   = "prod"
    }
    topology = {
      region  = "apne-kor-se"
      zone    = "apne-kor-se1"
      targets = ["sigsrv"]
    }
    nodes = {
      "c" : {
        type  = "controlplane"
        count = 1
      },
      "w" : {
        count = 2
      },
    }
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

    metrics_server = {
      enabled = true
    }

    registry = {
      enabled = true
    }

    tailscale = {
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
