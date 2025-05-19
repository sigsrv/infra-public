module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-p1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
  }

  talos = {
    version = "v1.10.2"
  }

  kubernetes = {
    cluster = {
      name     = "sigsrv-p1"
      alias    = "p1"
      env      = "prod"
      endpoint = "https://p1c0.sigsrv.local:6443"
    }
    topology = {
      region  = "apne-kor-se"
      zone    = "apne-kor-se1"
      targets = ["sigsrv", "twinsrv", "minisrv", "twinsrv", "twinsrv", "twinsrv"]
    }
    nodes = {
      "c" : {
        type   = "controlplane"
        count  = 3
        cpu    = 4
        memory = "4GiB"
      },
      "s" : {
        count  = 3
        cpu    = 4
        memory = "4GiB"
        disks = {
          "data" = {
            pool = "nvme"
            size = "100GiB"
          }
        }
        labels = {
          "kubernetes.sigsrv.net/role" = "storage"
        }
        taints = {
          "kubernetes.sigsrv.net/role" = "storage:NoSchedule"
        }
      }
      "w" : {
        count  = 6
        cpu    = 4
        memory = "4GiB"
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

    local_path_provisioner = {
      enabled = true
    }

    registry = {
      enabled = true
    }

    seaweedfs = {
      enabled = true
    }

    tailscale = {
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
