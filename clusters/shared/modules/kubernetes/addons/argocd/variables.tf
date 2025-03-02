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
    tags       = list(string)
  })
}

variable "tailscale" {
  type = object({
    tailnet = string
  })
}

variable "argocd" {
  type = object({
    version       = string
    keybase_users = list(string)
  })
}
