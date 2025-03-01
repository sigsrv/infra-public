terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.2.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

provider "incus" {
  remote {
    name    = "sigsrv"
    scheme  = "https"
    address = "sigsrv.deer-neon.ts.net"
    default = true
  }
}

provider "talos" {}

provider "kubernetes" {
  config_path = "${path.root}/kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.root}/kubeconfig"
  }
}

provider "kubectl" {
  config_path = "${path.root}/kubeconfig"
}

provider "onepassword" {
  account = "my.1password.com"
}
