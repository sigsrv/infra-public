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

variable "tailscale" {
  type = object({
    version = string
  })
}
