output "config" {
  value = {
    kubernetes  = var.kubernetes
    tailscale   = var.tailscale
    onepassword = var.onepassword
    addons      = var.addons
  }
}
