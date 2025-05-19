module "cluster" {
  source = "../../../modules/talos/cluster"

  incus = {
    project_name      = "sigsrv-d1"
    network_name      = "sigsrvbr0"
    network_zone_name = "sigsrv.local"
  }

  talos = {
    version = "v1.9.3"
  }

  kubernetes = {
    cluster = {
      name     = "sigsrv-d1"
      alias    = "d1"
      env      = "dev"
      endpoint = "https://d1c0.sigsrv.local:6443"
    }
    topology = {
      region  = "apne-kor-se"
      zone    = "apne-kor-se1"
      targets = ["minisrv"]
    }
    nodes = {
      "c" : {
        type  = "controlplane"
        count = 1
      },
      "w" : {
        count = 1
      },
    }
  }
}

module "addons" {
  source = "../../../modules/kubernetes/addons"
  count  = module.cluster.ready ? 1 : 0

  kubernetes = module.cluster.config.kubernetes

  onepassword = {
    vault_name = "sigsrv-sdlc"
  }

  addons = {
    metrics_server = {
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
