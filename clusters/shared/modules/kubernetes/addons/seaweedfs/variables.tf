variable "kubernetes" {
  type = object({
    cluster_name  = string
    cluster_alias = string
    cluster_env   = string
  })
}

variable "seaweedfs" {
  type = object({
    enabled = bool
    operator = object({
      version = string
    })
    csi_driver = object({
      version = string
      name    = string
      image   = string
    })
    seaweed = object({
      name                     = string
      image                    = string
      volume_server_disk_count = number
      master = object({
        replicas             = number
        volume_size_limit_mb = number
      })
      volume = object({
        replicas           = number
        storage            = string
        storage_class_name = string
      })
      filer = object({
        replicas = number
        config   = string
      })
    })
    storage_class = object({
      name             = string
      is_default_class = bool
      parameters       = map(string)
    })
  })
}
