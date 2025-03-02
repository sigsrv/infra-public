variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "addons" {
  type = object({
    argocd = optional(object({
      enabled = optional(bool, false)
    }), {})

    cloudnative_pg = optional(object({
      enabled = optional(bool, false)
    }), {})

    local_path_provisioner = optional(object({
      enabled = optional(bool, false)
    }), {})

    openbao = optional(object({
      enabled = optional(bool, false)
    }), {})

    registry = optional(object({
      enabled = optional(bool, false)
    }), {})

    tailscale_operator = optional(object({
      enabled = optional(bool, false)
    }), {})
  })

  default = {}
}
