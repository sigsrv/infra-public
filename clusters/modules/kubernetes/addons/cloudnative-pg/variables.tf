variable "kubernetes" {
  type = object({
    cluster = object({
      name  = string
      alias = string
      env   = string
    })
  })
}

variable "cloudnative_pg" {
  type = object({
    version = string
  })
}
