variable "kubernetes_host" {
  type    = string
  default = "https://sigsrv-sdlc-k3s-master-0:6443"
}

variable "vault_address" {
  type    = string
  default = "https://vault-sdlc.deer-neon.ts.net"
}
