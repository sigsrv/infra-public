provider "consul" {
  #  scheme  = "https"
  #  address = "consul.deer-neon.ts.net"
  address = "localhost:61963"
  token   = var.consul_token
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "microk8s"
}

variable "consul_token" {
  sensitive = true
}
