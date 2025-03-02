variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "onepassword" {
  type = object({
    vault_name = string
  })
}

variable "addons" {
  type = object({
    argocd = optional(object({
      enabled = optional(bool, false)
      # https://github.com/argoproj/argo-helm/releases
      version = optional(string, "7.8.7")
    }), {})

    cloudnative_pg = optional(object({
      enabled = optional(bool, false)
      # https://github.com/cloudnative-pg/charts/releases
      version = optional(string, "0.23.0")
    }), {})

    local_path_provisioner = optional(object({
      enabled = optional(bool, false)
    }), {})

    openbao = optional(object({
      enabled = optional(bool, false)
      # https://github.com/openbao/openbao-helm/releases
      version = optional(string, "0.8.1")
    }), {})

    registry = optional(object({
      enabled = optional(bool, false)
      # https://github.com/distribution/distribution/release
      version = optional(string, "2.8.1")
    }), {})

    tailscale_operator = optional(object({
      enabled = optional(bool, false)
      # https://artifacthub.io/packages/helm/tailscale/tailscale-operator
      version = optional(string, "1.78.3")
    }), {})
  })

  default = {}
}
