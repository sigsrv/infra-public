module "network" {
  for_each = var.networks
  source   = "./modules/network"
  name     = each.key
  network  = each.value
}

resource "null_resource" "protection" {
  lifecycle {
    prevent_destroy = true
  }
}
