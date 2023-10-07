module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}
