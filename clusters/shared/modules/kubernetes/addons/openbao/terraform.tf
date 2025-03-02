terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.1"
    }
  }
}
