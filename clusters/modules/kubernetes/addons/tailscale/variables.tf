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
  })
}

variable "tailscale" {
  type = object({
    version = string
  })
}
