variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "tailscale" {
  type = object({
    tailnet = optional(string, "deer-neon.ts.net")
  })

  default = {}
}

variable "onepassword" {
  type = object({
    vault_name = string
    tags = optional(list(string), [
      "Managed/Terraform",
      "Server/sigsrv",
    ])
  })
}

variable "addons" {
  type = object({
    argocd = optional(object({
      enabled = optional(bool, false)
      # https://github.com/argoproj/argo-helm/releases
      version       = optional(string, "7.8.7")
      keybase_users = optional(list(string), ["ecmaxp"])
    }), {})

    cert_manager = optional(object({
      enabled = optional(bool, false)
      # https://github.com/cert-manager/cert-manager/releases
      version = optional(string, "1.17.1")
    }), {})

    cloudnative_pg = optional(object({
      enabled = optional(bool, false)
      # https://github.com/cloudnative-pg/charts/releases
      version = optional(string, "0.23.0")
    }), {})

    local_path_provisioner = optional(object({
      enabled = optional(bool, false)
    }), {})

    metrics_server = optional(object({
      enabled = optional(bool, false)
      # https://artifacthub.io/packages/helm/metrics-server/metrics-server
      version = optional(string, "3.12.2")
    }), {})

    openbao = optional(object({
      enabled = optional(bool, false)
      # https://github.com/openbao/openbao-helm/releases
      version  = optional(string, "0.12.0")
      replicas = optional(number, 3)
      # pgp
      pgp_keys = optional(list(string), [
        "715FE376816038A7.pub",
        "685C7B17D23F1A3E.pub",
        "BC346E1E0C2D56CF.pub",
      ])
      root_token_pgp_key = optional(string, "BC346E1E0C2D56CF.pub")
      key_shares         = optional(number, 3)
      key_threshold      = optional(number, 2)
    }), {})

    registry = optional(object({
      enabled = optional(bool, false)
      # https://github.com/distribution/distribution/release
      version = optional(string, "2.8.1")
    }), {})

    rook_ceph = optional(object({
      enabled = optional(bool, false)
      # https://github.com/rook/rook/releases
      version = optional(string, "v1.17.1")
    }), {})

    seaweedfs = optional(object({
      enabled = optional(bool, false)
      # https://github.com/seaweedfs/seaweedfs
      version = optional(string, "4.0.387")
      csi_driver = optional(object({
        enabled = optional(bool, true)
        # https://github.com/seaweedfs/seaweedfs-csi-driver
        version = optional(string, "0.2.2")
      }), {})
    }), {})

    tailscale = optional(object({
      enabled = optional(bool, false)
      # https://artifacthub.io/packages/helm/tailscale/tailscale-operator
      version = optional(string, "1.82.5")
    }), {})
  })

  default = {}
}

variable "status" {
  default = "running"

  validation {
    condition     = contains(["ready", "running"], var.status)
    error_message = "Invalid status: ${var.status}"
  }
}
