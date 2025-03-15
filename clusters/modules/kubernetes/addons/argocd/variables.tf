variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
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
