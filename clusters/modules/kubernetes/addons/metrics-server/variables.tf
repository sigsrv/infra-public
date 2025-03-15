variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "metrics_server" {
  type = object({
    version = string
  })
}
