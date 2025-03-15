variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "cert_manager" {
  type = object({
    version = string
  })
}
