module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-p1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
  }

  talos = {
    version = "v1.9.3"
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
      targets = ["sigsrv", "sigsrv", "minisrv"]
    }
    nodes = {
      "c" : {
        type   = "controlplane"
        count  = 3
        cpu    = 4
        memory = "8GiB"
      },
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

  depends_on = [
    module.cluster
  ]
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
