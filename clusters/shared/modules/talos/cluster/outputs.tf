output "config" {
  value = {
    incus      = var.incus
    talos      = var.talos
    kubernetes = var.kubernetes
  }
}
