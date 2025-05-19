variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "seaweedfs" {
  type = object({
    enabled = bool
    version = string
    csi_driver = object({
      enabled = bool
      version = string
    })
  })
}
