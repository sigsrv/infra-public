resource "incus_project" "network" {
  name        = "incus-network"
  description = "incus-network (managed by OpenTofu)"
}

module "network" {
  for_each = var.networks
  source   = "./modules/network"
  name     = each.key
  network  = each.value

  depends_on = [incus_project.network]
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
