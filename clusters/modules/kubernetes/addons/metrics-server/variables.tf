variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "metrics_server" {
  type = object({
    version = string
  })
}
