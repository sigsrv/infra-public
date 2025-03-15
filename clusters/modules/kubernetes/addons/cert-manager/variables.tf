variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "cert_manager" {
  type = object({
    version = string
  })
}
