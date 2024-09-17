variable "kubernetes_cluster_name" {
  type = string
}

variable "kubernetes_app_name" {
  type = string
}

variable "kubernetes_app_namespace" {
  type = string
}

variable "kubernetes_app_role" {
  type    = string
  default = null
}
