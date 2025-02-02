terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.root}/../../cluster/kubeconfig"
}

provider "kubectl" {
  config_path = "${path.root}/../../cluster/kubeconfig"
}
