variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "cloudnative_pg" {
  type = object({
    version = string
  })
}
