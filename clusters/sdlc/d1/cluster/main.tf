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
      name  = "sigsrv-d1"
      alias = "d1"
      env   = "dev"
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

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
