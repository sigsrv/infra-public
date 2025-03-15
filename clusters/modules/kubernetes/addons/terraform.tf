terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
    }

    onepassword = {
      source = "1Password/onepassword"
    }
  }
}
