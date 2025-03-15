terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    onepassword = {
      source = "1Password/onepassword"
    }
  }
}
