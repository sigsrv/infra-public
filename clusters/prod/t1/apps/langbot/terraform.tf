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

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.1"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.root}/../../cluster/kubeconfig"
}

provider "kubectl" {
  config_path = "${path.root}/../../cluster/kubeconfig"
}

provider "onepassword" {
  account = "my.1password.com"
}
