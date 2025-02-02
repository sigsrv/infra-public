variable "name" {
  type = string
}

variable "onepassword_vault" {
  type = string
}

variable "onepassword_items" {
  type = map(string)
}

variable "deployments" {
  type = list(string)
}

variable "manifests" {
  type = list(string)
}
