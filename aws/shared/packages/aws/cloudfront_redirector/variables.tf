variable "domain_names" {
  type = list(string)
}

variable "route53_records" {
  type = map(object({
    zone_id = string
    name    = optional(string)
  }))
}

variable "target_url" {
  type = string
}
