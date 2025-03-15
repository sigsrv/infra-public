variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "rook_ceph" {
  type = object({
    enabled = bool
    version = string
  })
}
