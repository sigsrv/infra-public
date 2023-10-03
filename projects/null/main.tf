module "metadata" {
  source = "../../modules/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}
