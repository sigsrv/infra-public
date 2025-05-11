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
  host                   = module.cluster.kubernetes.host
  cluster_ca_certificate = base64decode(module.cluster.kubernetes.ca_certificate)
  client_certificate     = base64decode(module.cluster.kubernetes.client_certificate)
  client_key             = base64decode(module.cluster.kubernetes.client_key)
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.kubernetes.host
    cluster_ca_certificate = base64decode(module.cluster.kubernetes.ca_certificate)
    client_certificate     = base64decode(module.cluster.kubernetes.client_certificate)
    client_key             = base64decode(module.cluster.kubernetes.client_key)
  }
}

provider "kubectl" {
  host                   = module.cluster.kubernetes.host
  cluster_ca_certificate = base64decode(module.cluster.kubernetes.ca_certificate)
  client_certificate     = base64decode(module.cluster.kubernetes.client_certificate)
  client_key             = base64decode(module.cluster.kubernetes.client_key)
}

provider "onepassword" {
  account = "my.1password.com"
}
