module "network" {
  for_each = var.networks
  source   = "./network"
  name     = each.key
  network  = each.value
}
