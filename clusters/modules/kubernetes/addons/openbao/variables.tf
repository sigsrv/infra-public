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

variable "openbao" {
  type = object({
    version            = string
    replicas           = number
    pgp_keys           = list(string)
    root_token_pgp_key = string
    key_shares         = number
    key_threshold      = number
  })
}
