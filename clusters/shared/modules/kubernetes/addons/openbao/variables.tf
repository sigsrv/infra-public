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
