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

variable "vault_public_url" {
  type = string
}

variable "vault_internal_url" {
  type = string
}

variable "vault_pki_path" {
  type = string
}

variable "vault_pki_ca_cert_type" {
  type = string
}

variable "vault_pki_ca_cert_certificate" {
  type = string
}
