variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "rook_ceph" {
  type = object({
    enabled = bool
    version = string
  })
}
