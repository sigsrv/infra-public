output "config" {
  value = {
    incus      = var.incus
    talos      = var.talos
    kubernetes = var.kubernetes
  }
}

output "ready" {
  value = length(talos_machine_bootstrap.this) > 0
}
